//
//  Graph.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// A directed graph describing a single ordered relationship between nodes.
///
/// A graph is a value type. Copying a graph is a constant time operation, and
/// the copy is fully independent of the original, so a graph can be snapshotted
/// freely, handed to another thread, or retained as an undo state without
/// coordination.
///
/// A node is an identifier, not a payload. Any `Hashable` type can be used, and
/// the data the node refers to is expected to live elsewhere.
///
/// ```swift
/// var parenting = Graph<UUID, Void>(options: .acyclic)
///
/// parenting.insert(document)
/// parenting.insert(layer)
///
/// try parenting.connect(document, to: layer)
/// ```
///
/// Each graph models exactly one relationship. To describe several relationships
/// over the same nodes, use several graphs sharing the same identifier type.
///
/// ```swift
/// var dependencies = Graph<UUID, Void>(options: .acyclic)
/// var parenting = Graph<UUID, Void>(options: .tree)
/// ```
///
/// ## Ordering
///
/// The edges connected to a node are ordered, and the ordering is stable for the
/// lifetime of the graph. Each node maintains a separate ordering for its
/// outgoing and its incoming edges, so an edge occupies an independent position
/// at each of its endpoints. Edges can be inserted at, and moved to, an explicit
/// ``EdgePosition``.
///
/// ## Value
///
/// Each edge carries a value of the graph's `Value` type. This can be used to
/// store a weight, a label, a payload, or nothing at all.
///
/// ```swift
/// var costs = Graph<String, Double>()
/// try costs.connect("London", to: "Paris", value: 344.0)
/// ```
///
/// For a graph that carries no value, use `Void`. The ``connect(_:to:at:)``
/// overload omits the value entirely in that case.
///
public struct Graph<Node: Hashable, Value> {
/// The storage describing a single node, and the ordered edges connected to
/// it in each direction.
///
	internal struct NodeRecord {
	/// The identifier the node is addressed by.
	///
		internal var node: Node

	/// The ordered edges that leave the node.
	///
		internal var outgoing: [Edge]

	/// The ordered edges that arrive at the node.
	///
		internal var incoming: [Edge]

	/// Initialize a record describing a node that is not yet connected to
	/// anything.
	///
	/// - Parameters:
	///   - node: The identifier the node is addressed by.
	///
		internal init(node: Node) {
			self.node = node
			self.outgoing = []
			self.incoming = []
		}
	}

/// The storage describing a single edge.
///
/// The endpoints are stored as node slots rather than node identifiers, so
/// that the cost of an edge is independent of the size of the identifier
/// type, and so that traversal never needs to hash.
///
	internal struct EdgeRecord {
	/// The slot storing the node the edge leaves.
	///
		internal var source: Int

	/// The slot storing the node the edge arrives at.
	///
		internal var target: Int

	/// The value carried by the edge.
	///
		internal var value: Value

	/// Initialize a record describing an edge between two nodes.
	///
	/// - Parameters:
	///   - source: The slot storing the node the edge leaves.
	///   - target: The slot storing the node the edge arrives at.
	///   - value: The value carried by the edge.
	///
		internal init(source: Int, target: Int, value: Value) {
			self.source = source
			self.target = target
			self.value = value
		}
	}

/// The nodes in the graph, stored in a slot map addressed by a dense
/// integer.
///
/// Removing a node vacates its slot, leaving nil behind. The slot is
/// recycled by the next insertion.
///
	internal var nodeRecords: [NodeRecord?]

/// The slot storing each node, used to address a node by its identifier.
///
/// This is the only place a node identifier is hashed. Every other part of
/// the graph refers to a node by its slot.
///
	internal var nodeSlots: [Node: Int]

/// The node slots that have been vacated, and are available to be recycled.
///
	internal var vacantNodeSlots: [Int]

/// The edges in the graph, stored in a slot map addressed by a dense
/// integer.
///
	internal var edgeRecords: [EdgeRecord?]

/// The number of times each edge slot has been vacated.
///
/// The generation is carried by every ``Edge`` handle, so a handle referring
/// to a disconnected edge can be distinguished from one referring to the
/// edge that later recycled its slot.
///
	internal var edgeGenerations: [UInt32]

/// The edge slots that have been vacated, and are available to be recycled.
///
	internal var vacantEdgeSlots: [Int]

/// The changes made to the topology of the graph by the transaction
/// currently in progress.
///
/// A nil log indicates that no transaction is in progress, so a mutation
/// that nobody is observing costs nothing to record.
///
	internal var changeLog: [Change]?

/// The topology the graph is permitted to represent.
///
/// The options are fixed when the graph is initialized, and are enforced
/// every time an edge is connected.
///
	public let options: GraphOptions

/// Initialize an empty graph.
///
/// - Parameters:
///   - options: The topology the graph is permitted to represent. Defaults
///   to ``GraphOptions/default``, describing an unconstrained directed
///   multigraph.
///
	public init(options: GraphOptions = .default) {
		self.nodeRecords = []
		self.nodeSlots = [:]
		self.vacantNodeSlots = []
		self.edgeRecords = []
		self.edgeGenerations = []
		self.vacantEdgeSlots = []
		self.changeLog = nil
		self.options = options
	}

/// Initialize a graph containing the provided nodes and no edges.
///
/// - Parameters:
///   - nodes: The nodes to insert into the graph. Duplicates are ignored.
///   - options: The topology the graph is permitted to represent.
///
	public init(nodes: some Sequence<Node>, options: GraphOptions = .default) {
		self.init(options: options)

		for node in nodes {
			insert(node)
		}
	}
}

extension Graph {
/// An opaque handle referring to an edge in the graph.
///
/// A handle remains valid until the edge it refers to is disconnected, either
/// directly or as a consequence of removing one of its endpoints. Handles are
/// unaffected by any other mutation, so an edge can be reordered, or the
/// graph grown and shrunk around it, without invalidating it.
///
/// A handle obtained from one graph should not be used with another. Handles
/// are validated against the graph they are used with, so a stale handle is
/// reported as a missing edge rather than silently addressing an unrelated
/// one.
///
	public struct Edge {
	/// The slot storing the edge.
	///
		internal var slot: Int

	/// The number of times the slot had been vacated when the handle was
	/// created.
	///
	/// A handle whose generation no longer matches the graph refers to an
	/// edge that has been disconnected.
	///
		internal var generation: UInt32

	/// Initialize a handle referring to an edge in a specific slot.
	///
	/// - Parameters:
	///   - slot: The slot storing the edge.
	///   - generation: The number of times the slot has been vacated.
	///
		internal init(slot: Int, generation: UInt32) {
			self.slot = slot
			self.generation = generation
		}
	}
}

extension Graph: CustomStringConvertible where Node: CustomStringConvertible {
/// A textual description of the graph, listing each node alongside the nodes
/// its outgoing edges arrive at, in order.
///
	public var description: String {
		var description = "Graph (\(nodeCount) nodes, \(edgeCount) edges)"

		for node in nodes {
			let successors = successors(of: node)
			if successors.isEmpty {
				description += "\n  \(node)"
			}
			else {
				description += "\n  \(node) → " + successors.map(\.description).joined(separator: ", ")
			}
		}

		return description
	}
}

extension Graph: Sendable where Node: Sendable, Value: Sendable {

}

extension Graph.NodeRecord: Sendable where Node: Sendable {

}

extension Graph.EdgeRecord: Sendable where Value: Sendable {

}

extension Graph.Edge: Equatable {

}

extension Graph.Edge: Hashable {

}

extension Graph.Edge: Sendable {

}
