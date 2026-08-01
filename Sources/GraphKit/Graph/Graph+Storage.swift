//
//  Graph+Storage.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

// The graph maintains the invariant that a slot recorded in `nodeSlots`, or
// referenced by an `EdgeRecord`, always stores a record. The force unwraps
// throughout this file assert that invariant. A trap here indicates a bug in
// the graph itself, and cannot be provoked through the public API.
//
extension Graph {
/// The number of node slots that have ever been allocated, including those
/// that are currently vacant.
///
/// This is the upper bound for any slot addressed array, and is used by the
/// algorithms to size their dense working storage.
///
	internal var slotCapacity: Int {
		nodeRecords.count
	}

/// Looks up the node stored in the provided slot.
///
/// - Parameters:
///   - slot: The slot to look up. This must store a node.
///
/// - Returns: The node stored in the slot.
///
	internal func node(inSlot slot: Int) -> Node {
		nodeRecords[slot]!.node
	}

/// Looks up the ordered edges connected to the node in the provided slot.
///
/// - Parameters:
///   - slot: The slot to look up. This must store a node.
///   - direction: The direction the edges are connected in.
///
/// - Returns: The ordered edges connected to the node.
///
	internal func edges(inSlot slot: Int, in direction: EdgeDirection) -> [Edge] {
		switch direction {
			case .outgoing:
				return nodeRecords[slot]!.outgoing
			case .incoming:
				return nodeRecords[slot]!.incoming
		}
	}

/// Replaces the ordered edges connected to the node in the provided slot.
///
/// - Parameters:
///   - edges: The ordered edges to store.
///   - slot: The slot to store the edges in. This must store a node.
///   - direction: The direction the edges are connected in.
///
	internal mutating func setEdges(_ edges: [Edge], inSlot slot: Int, in direction: EdgeDirection) {
		switch direction {
			case .outgoing:
				nodeRecords[slot]!.outgoing = edges
			case .incoming:
				nodeRecords[slot]!.incoming = edges
		}
	}

/// Looks up the record describing the provided edge, validating the handle
/// against the graph.
///
/// - Parameters:
///   - edge: The edge to look up.
///
/// - Returns: The record describing the edge, or nil if the handle does not
///   refer to an edge in the graph.
///
	internal func record(for edge: Edge) -> EdgeRecord? {
		guard edge.slot >= 0, edge.slot < edgeRecords.count else {
			return nil
		}

		guard edgeGenerations[edge.slot] == edge.generation else {
			return nil
		}

		return edgeRecords[edge.slot]
	}

/// Walks an edge from one of its endpoints towards the other.
///
/// - Parameters:
///   - edge: The edge to walk. This must be a member of the graph.
///   - direction: The direction to walk the edge in. Walking an outgoing
///   edge arrives at its target, and walking an incoming edge arrives at its
///   source.
///
/// - Returns: The slot storing the node at the far end of the edge.
///
	internal func slot(traversing edge: Edge, in direction: EdgeDirection) -> Int {
		switch direction {
			case .outgoing:
				return edgeRecords[edge.slot]!.target
			case .incoming:
				return edgeRecords[edge.slot]!.source
		}
	}

/// Allocates a slot for a new node, growing the storage if no slot is vacant.
///
/// - Parameters:
///   - node: The node to store.
///
/// - Returns: The slot the node was stored in.
///
	internal mutating func allocateSlot(for node: Node) -> Int {
		if let slot = vacantNodeSlots.popLast() {
			nodeRecords[slot] = NodeRecord(node: node)
			return slot
		}

		nodeRecords.append(NodeRecord(node: node))
		return nodeRecords.count - 1
	}

/// Allocates a slot for a new edge, growing the storage if no slot is vacant.
///
/// - Parameters:
///   - source: The slot storing the node the edge leaves.
///   - target: The slot storing the node the edge arrives at.
///   - value: The value carried by the edge.
///
/// - Returns: A handle referring to the newly allocated edge.
///
	internal mutating func allocateEdge(source: Int, target: Int, value: Value) -> Edge {
		let record = EdgeRecord(source: source, target: target, value: value)

		if let slot = vacantEdgeSlots.popLast() {
			edgeRecords[slot] = record
			return Edge(slot: slot, generation: edgeGenerations[slot])
		}

		edgeRecords.append(record)
		edgeGenerations.append(0)

		return Edge(slot: edgeRecords.count - 1, generation: 0)
	}

/// Vacates the slot storing the provided edge, invalidating every handle
/// referring to it.
///
/// The edge is not detached from its endpoints; the caller is responsible for
/// doing so before calling this.
///
/// - Parameters:
///   - edge: The edge to deallocate. This must be a member of the graph.
///
	internal mutating func deallocateEdge(_ edge: Edge) {
		edgeRecords[edge.slot] = nil
		edgeGenerations[edge.slot] &+= 1
		vacantEdgeSlots.append(edge.slot)
	}

/// Tests whether the node in one slot can be reached by walking the graph
/// forwards from the node in another.
///
/// A node is always considered to reach itself.
///
/// - Parameters:
///   - source: The slot to walk from. This must store a node.
///   - target: The slot being searched for.
///
/// - Returns: True if the target can be reached from the source.
///
	internal func slot(_ source: Int, reaches target: Int) -> Bool {
		if source == target {
			return true
		}

		var visited = [Bool](repeating: false, count: slotCapacity)
		var pending = [source]
		visited[source] = true

		while let slot = pending.popLast() {
			guard let record = nodeRecords[slot] else {
				continue
			}

			for edge in record.outgoing {
				let next = edgeRecords[edge.slot]!.target
				if next == target {
					return true
				}

				if visited[next] == false {
					visited[next] = true
					pending.append(next)
				}
			}
		}

		return false
	}
}
