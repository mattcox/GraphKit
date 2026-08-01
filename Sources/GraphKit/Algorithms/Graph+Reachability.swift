//
//  Graph+Reachability.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// Tests whether one node can be reached from another by walking the graph.
///
/// A node always reaches itself, whether or not it is connected to itself.
///
/// - Parameters:
///   - target: The node being searched for.
///   - source: The node to walk from.
///   - direction: The direction to walk the edges in. Defaults to
///   ``EdgeDirection/outgoing``.
///
/// - Returns: True if the target node can be reached from the source node.
///
	public func reaches(_ target: Node, from source: Node, in direction: EdgeDirection = .outgoing) -> Bool {
		guard let sourceSlot = nodeSlots[source], let targetSlot = nodeSlots[target] else {
			return false
		}

		if direction == .outgoing {
			return slot(sourceSlot, reaches: targetSlot)
		}

		return slot(targetSlot, reaches: sourceSlot)
	}

/// The nodes that can be reached from the provided node by walking the graph.
///
/// The starting node is included only if it is part of a cycle that returns
/// to it.
///
/// - Parameters:
///   - node: The node to walk from.
///   - direction: The direction to walk the edges in. Defaults to
///   ``EdgeDirection/outgoing``.
///
/// - Returns: The nodes that can be reached from the node.
///
	public func nodes(reachableFrom node: Node, in direction: EdgeDirection = .outgoing) -> [Node] {
		guard let origin = nodeSlots[node] else {
			return []
		}

		var reachable: [Node] = []
		var isOriginReachable = false

		var visited = [Bool](repeating: false, count: slotCapacity)
		var pending = [origin]

		visited[origin] = true

		var front = 0
		while front < pending.count {
			let slot = pending[front]
			front += 1

			for edge in edges(inSlot: slot, in: direction) {
				let next = self.slot(traversing: edge, in: direction)

				// The node the walk started from is only genuinely reachable
				// if the walk returns to it.
				//
				if next == origin {
					isOriginReachable = true
				}

				if visited[next] == false {
					visited[next] = true
					pending.append(next)
				}
			}

			if slot != origin {
				reachable.append(self.node(inSlot: slot))
			}
		}

		if isOriginReachable {
			reachable.append(node)
		}

		return reachable
	}

/// Indicates whether the graph contains no directed cycles.
///
/// A graph that does not contain ``GraphOptions/allowsCycles`` is acyclic by
/// construction, and this is always true.
///
	public var isAcyclic: Bool {
		topologicallySorted() != nil
	}

/// Tests whether connecting one node to another would introduce a directed
/// cycle.
///
/// This is the test performed by ``connect(_:to:value:at:)`` in a graph that
/// does not contain ``GraphOptions/allowsCycles``, exposed so that a
/// connection can be validated ahead of being attempted.
///
/// - Parameters:
///   - source: The node the edge would leave.
///   - target: The node the edge would arrive at.
///
/// - Returns: True if connecting the nodes would introduce a cycle. This is
///   false if either node is not a member of the graph, as the connection
///   would be rejected regardless.
///
	public func wouldCreateCycle(connecting source: Node, to target: Node) -> Bool {
		guard let sourceSlot = nodeSlots[source], let targetSlot = nodeSlots[target] else {
			return false
		}

		return slot(targetSlot, reaches: sourceSlot)
	}
}
