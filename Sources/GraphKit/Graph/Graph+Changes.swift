//
//  Graph+Changes.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// A description of a single change to the topology of a graph.
///
/// Changes describe topology only. The value carried by an edge is not part
/// of the topology, so replacing it using ``setValue(_:of:)`` is not
/// reported.
///
	public enum Change {
	/// A node was inserted into the graph.
	///
	/// - Parameters:
	///   - node: The node that was inserted.
	///
		case nodeInserted(_ node: Node)

	/// A node was removed from the graph.
	///
	/// Every edge connected to the node is reported as being disconnected
	/// ahead of this change.
	///
	/// - Parameters:
	///   - node: The node that was removed.
	///
		case nodeRemoved(_ node: Node)

	/// An edge was connected between two nodes.
	///
	/// - Parameters:
	///   - edge: A handle referring to the edge that was connected.
	///   - source: The node the edge leaves.
	///   - target: The node the edge arrives at.
	///   - index: The position the edge was inserted at within the source
	///   node's ordered outgoing edges.
	///
		case edgeInserted(_ edge: Edge, source: Node, target: Node, index: Int)

	/// An edge was disconnected from the two nodes it connected.
	///
	/// The handle is invalid by the time the change is delivered, and is
	/// provided so that the edge can be correlated with the change that
	/// inserted it.
	///
	/// - Parameters:
	///   - edge: A handle referring to the edge that was disconnected.
	///   - source: The node the edge left.
	///   - target: The node the edge arrived at.
	///
		case edgeRemoved(_ edge: Edge, source: Node, target: Node)

	/// An edge was moved within the ordered edges connected to one of its
	/// endpoints.
	///
	/// - Parameters:
	///   - edge: A handle referring to the edge that was moved.
	///   - from: The position the edge was moved from.
	///   - to: The position the edge was moved to.
	///   - direction: The ordering the edge was moved within.
	///
		case edgeMoved(_ edge: Edge, from: Int, to: Int, direction: EdgeDirection)
	}
}

extension Graph {
/// Records a change, if a recording is currently in progress.
///
/// - Parameters:
///   - change: The change to record.
///
	internal mutating func appendChange(_ change: Change) {
		changeLog?.append(change)
	}

/// Performs a group of mutations as a single transaction, reporting the
/// changes they made to the topology of the graph.
///
/// Mutations performed inside the body are applied to the graph immediately,
/// and are described in the order they occurred. If the body throws, the
/// graph is restored to the state it held before the transaction began, and
/// no changes are reported.
///
/// ```swift
/// let (edge, changes) = try graph.withChanges { graph in
///     graph.insert(layer)
///     return try graph.connect(document, to: layer)
/// }
///
/// for observer in observers {
///     observer.graph(graph, didChange: changes)
/// }
/// ```
///
/// Transactions nest. The changes made by an inner transaction are reported
/// by that transaction, and are also included in the changes reported by the
/// transaction enclosing it.
///
/// Mutations performed outside a transaction are not recorded, so observing a
/// graph costs nothing until it is observed.
///
/// - Parameters:
///   - body: A closure performing the mutations. The graph is provided
///   inout, and should be mutated in place.
///
/// - Returns: The value returned by the body, along with the changes the body
///   made to the topology of the graph.
///
	public mutating func withChanges<Result, Failure>(_ body: (inout Self) throws(Failure) -> Result) throws(Failure) -> (result: Result, changes: [Change]) {
		// Retain the state to restore should the body throw. The graph is a
		// value type backed by copy on write storage, so this is a constant
		// time operation.
		//
		let restore = self
		let enclosing = changeLog
		changeLog = []

		let result: Result
		do {
			result = try body(&self)
		}
		catch {
			self = restore
			changeLog = enclosing
			throw error
		}

		let changes = changeLog ?? []

		// Restore the enclosing recording, folding the changes made by this
		// transaction into it so that nested transactions are reported by
		// every transaction enclosing them.
		//
		changeLog = enclosing
		changeLog?.append(contentsOf: changes)

		return (result, changes)
	}
}

extension Graph.Change: Equatable {

}

extension Graph.Change: Hashable {

}

extension Graph.Change: Sendable where Node: Sendable {

}
