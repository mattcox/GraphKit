//
//  Graph+TopologicalSort.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// Orders every node in the graph so that each node appears before every node
/// it is connected to.
///
/// This is the order the graph must be evaluated in for the result of every
/// node to be available before it is needed. In a graph describing which
/// materials an item depends upon, it is the order the materials must be
/// built in.
///
/// ```swift
/// guard let order = dependencies.topologicallySorted() else {
///     throw BuildError.circularDependency
/// }
///
/// for material in order {
///     build(material)
/// }
/// ```
///
/// A graph containing a directed cycle cannot be ordered, as every node in
/// the cycle would have to appear before itself. A graph that does not
/// contain ``GraphOptions/allowsCycles`` can always be ordered.
///
/// Nodes that are not connected to each other are ordered relative to the
/// edges that reached them, so the result is stable for a given graph.
///
/// - Parameters:
///   - direction: The direction to order the nodes in. Ordering by outgoing
///   edges places each node before its successors, and ordering by incoming
///   edges places each node before its predecessors. Defaults to
///   ``EdgeDirection/outgoing``.
///
/// - Returns: Every node in the graph, ordered so that no node appears before
///   a node it is reachable from, or nil if the graph contains a cycle.
///
	public func topologicallySorted(in direction: EdgeDirection = .outgoing) -> [Node]? {
		let incoming = direction.reversed

		// The number of edges arriving at each node that have not yet been
		// resolved. A node becomes ready once every node before it has been
		// ordered.
		//
		var remaining = [Int](repeating: 0, count: slotCapacity)
		var ready: [Int] = []

		for slot in nodeRecords.indices where nodeRecords[slot] != nil {
			let count = edges(inSlot: slot, in: incoming).count
			remaining[slot] = count

			if count == 0 {
				ready.append(slot)
			}
		}

		var sorted: [Node] = []
		sorted.reserveCapacity(nodeCount)

		var front = 0
		while front < ready.count {
			let slot = ready[front]
			front += 1

			sorted.append(node(inSlot: slot))

			for edge in edges(inSlot: slot, in: direction) {
				let next = self.slot(traversing: edge, in: direction)

				remaining[next] -= 1
				if remaining[next] == 0 {
					ready.append(next)
				}
			}
		}

		// Any node that was never made ready is part of a cycle, or is
		// downstream of one.
		//
		guard sorted.count == nodeCount else {
			return nil
		}

		return sorted
	}
}
