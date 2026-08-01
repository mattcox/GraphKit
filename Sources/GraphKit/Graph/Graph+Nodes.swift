//
//  Graph+Nodes.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// The nodes in the graph, in no particular order.
///
	public var nodes: some Collection<Node> {
		nodeSlots.keys
	}

/// The number of nodes in the graph.
///
	public var nodeCount: Int {
		nodeSlots.count
	}

/// Indicates whether the graph contains no nodes.
///
/// A graph containing no nodes necessarily contains no edges.
///
	public var isEmpty: Bool {
		nodeSlots.isEmpty
	}

/// Tests whether the provided node is a member of the graph.
///
/// - Parameters:
///   - node: The node to test for.
///
/// - Returns: True if the node is a member of the graph.
///
	public func contains(_ node: Node) -> Bool {
		nodeSlots.index(forKey: node) != nil
	}

/// Inserts a node into the graph.
///
/// Inserting a node that is already a member of the graph has no effect, and
/// leaves its edges untouched.
///
/// - Parameters:
///   - node: The node to insert.
///
/// - Returns: True if the node was inserted, or false if it was already a
///   member of the graph.
///
	@discardableResult
	public mutating func insert(_ node: Node) -> Bool {
		guard nodeSlots.index(forKey: node) == nil else {
			return false
		}

		nodeSlots[node] = allocateSlot(for: node)
		appendChange(.nodeInserted(node))

		return true
	}

/// Inserts a collection of nodes into the graph.
///
/// Nodes that are already members of the graph are ignored.
///
/// - Parameters:
///   - nodes: The nodes to insert.
///
	public mutating func insert(contentsOf nodes: some Sequence<Node>) {
		for node in nodes {
			insert(node)
		}
	}

/// Removes a node from the graph, along with every edge connected to it.
///
/// Removing a node disconnects every edge that leaves or arrives at it. Each
/// disconnection is reported as a separate change, ahead of the change
/// reporting the removal of the node itself.
///
/// - Parameters:
///   - node: The node to remove.
///
/// - Returns: True if the node was removed, or false if it was not a member
///   of the graph.
///
	@discardableResult
	public mutating func remove(_ node: Node) -> Bool {
		guard let slot = nodeSlots.removeValue(forKey: node) else {
			return false
		}

		// Gather every edge connected to the node in either direction. A self
		// loop appears in both collections, so is deduplicated here to avoid
		// reporting it as being disconnected twice.
		//
		var incident = nodeRecords[slot]!.outgoing
		for edge in nodeRecords[slot]!.incoming where incident.contains(edge) == false {
			incident.append(edge)
		}

		for edge in incident {
			guard let record = edgeRecords[edge.slot] else {
				continue
			}

			let source = self.node(inSlot: record.source)
			let target = self.node(inSlot: record.target)

			// Detach the edge from the endpoint that is being kept. The
			// endpoint being removed is discarded wholesale below.
			//
			if record.source != slot {
				nodeRecords[record.source]!.outgoing.removeAll {
					$0 == edge
				}
			}

			if record.target != slot {
				nodeRecords[record.target]!.incoming.removeAll {
					$0 == edge
				}
			}

			deallocateEdge(edge)
			appendChange(.edgeRemoved(edge, source: source, target: target))
		}

		nodeRecords[slot] = nil
		vacantNodeSlots.append(slot)
		appendChange(.nodeRemoved(node))

		return true
	}

/// Removes every node and edge from the graph.
///
/// - Parameters:
///   - keepingCapacity: Indicates whether the storage backing the graph
///   should be preserved for reuse.
///
	public mutating func removeAll(keepingCapacity: Bool = false) {
		if changeLog != nil {
			// The changes are gathered ahead of being recorded, so that the
			// graph is not mutated while it is being enumerated.
			//
			let removedEdges = Array(edges)
			let removedNodes = Array(nodes)

			for edge in removedEdges {
				let record = self.record(for: edge)!
				appendChange(.edgeRemoved(edge, source: node(inSlot: record.source), target: node(inSlot: record.target)))
			}

			for node in removedNodes {
				appendChange(.nodeRemoved(node))
			}
		}

		nodeRecords.removeAll(keepingCapacity: keepingCapacity)
		nodeSlots.removeAll(keepingCapacity: keepingCapacity)
		vacantNodeSlots.removeAll(keepingCapacity: keepingCapacity)
		edgeRecords.removeAll(keepingCapacity: keepingCapacity)
		edgeGenerations.removeAll(keepingCapacity: keepingCapacity)
		vacantEdgeSlots.removeAll(keepingCapacity: keepingCapacity)
	}
}
