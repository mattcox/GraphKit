//
//  Graph+ShortestPath.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// The shortest path between two nodes, measured by the number of edges
/// walked.
///
/// Where several paths are equally short, the path found is the one that
/// walks the earliest ordered edges.
///
/// ```swift
/// if let path = graph.shortestPath(from: item, to: material) {
///     let nodes = graph.nodes(along: path, from: item)
/// }
/// ```
///
/// - Parameters:
///   - source: The node the path starts at.
///   - target: The node the path ends at.
///   - direction: The direction to walk the edges in. Defaults to
///   ``EdgeDirection/outgoing``.
///
/// - Returns: The ordered edges forming the shortest path between the nodes,
///   or nil if no path exists. A path from a node to itself is empty.
///
	public func shortestPath(from source: Node, to target: Node, in direction: EdgeDirection = .outgoing) -> [Edge]? {
		guard let sourceSlot = nodeSlots[source], let targetSlot = nodeSlots[target] else {
			return nil
		}

		if sourceSlot == targetSlot {
			return []
		}

		var visited = [Bool](repeating: false, count: slotCapacity)
		var arrival = [Edge?](repeating: nil, count: slotCapacity)
		var pending = [sourceSlot]

		visited[sourceSlot] = true

		var front = 0
		while front < pending.count {
			let slot = pending[front]
			front += 1

			for edge in edges(inSlot: slot, in: direction) {
				let next = self.slot(traversing: edge, in: direction)
				guard visited[next] == false else {
					continue
				}

				visited[next] = true
				arrival[next] = edge

				if next == targetSlot {
					return path(from: sourceSlot, to: targetSlot, arrivingBy: arrival, in: direction)
				}

				pending.append(next)
			}
		}

		return nil
	}

/// The shortest path between two nodes, measured by the total weight of the
/// edges walked.
///
/// The weight of each edge is derived from the value it carries. Weights must
/// not be negative; a graph containing a negative weight will produce an
/// undefined result rather than a diagnostic.
///
/// ```swift
/// let route = distances.shortestPath(from: "London", to: "Rome") { $0.kilometres }
/// ```
///
/// - Parameters:
///   - source: The node the path starts at.
///   - target: The node the path ends at.
///   - direction: The direction to walk the edges in. Defaults to
///   ``EdgeDirection/outgoing``.
///   - weight: A closure deriving the weight of an edge from the value it
///   carries.
///
/// - Returns: The ordered edges forming the shortest path between the nodes,
///   or nil if no path exists. A path from a node to itself is empty.
///
	public func shortestPath<Weight: Comparable & AdditiveArithmetic>(from source: Node, to target: Node, in direction: EdgeDirection = .outgoing, weight: (Value) -> Weight) -> [Edge]? {
		guard let sourceSlot = nodeSlots[source], let targetSlot = nodeSlots[target] else {
			return nil
		}

		if sourceSlot == targetSlot {
			return []
		}

		var distance = [Weight?](repeating: nil, count: slotCapacity)
		var arrival = [Edge?](repeating: nil, count: slotCapacity)
		var settled = [Bool](repeating: false, count: slotCapacity)

		var pending = PriorityQueue<Weight, Int>()
		pending.reserveCapacity(nodeCount)

		distance[sourceSlot] = .zero
		pending.insert(sourceSlot, priority: .zero)

		while let (total, slot) = pending.removeMinimum() {
			// The queue holds an entry for every improvement made to a node,
			// so an entry that has already been settled is stale.
			//
			guard settled[slot] == false else {
				continue
			}

			settled[slot] = true

			if slot == targetSlot {
				return path(from: sourceSlot, to: targetSlot, arrivingBy: arrival, in: direction)
			}

			for edge in edges(inSlot: slot, in: direction) {
				let next = self.slot(traversing: edge, in: direction)
				guard settled[next] == false else {
					continue
				}

				let candidate = total + weight(edgeRecords[edge.slot]!.value)
				if let existing = distance[next], existing <= candidate {
					continue
				}

				distance[next] = candidate
				arrival[next] = edge
				pending.insert(next, priority: candidate)
			}
		}

		return nil
	}

/// The nodes visited by walking a path, starting at the provided node.
///
/// The starting node is the first node returned, so a path of `n` edges
/// describes `n + 1` nodes. An empty path describes the starting node alone.
///
/// - Parameters:
///   - path: The ordered edges forming the path, as returned by
///   ``shortestPath(from:to:in:)``.
///   - node: The node the path starts at.
///   - direction: The direction the path walks the edges in. Defaults to
///   ``EdgeDirection/outgoing``.
///
/// - Returns: The ordered nodes visited by walking the path, or nil if the
///   path does not describe a connected walk from the node.
///
	public func nodes(along path: [Edge], from node: Node, in direction: EdgeDirection = .outgoing) -> [Node]? {
		guard var slot = nodeSlots[node] else {
			return nil
		}

		var walked = [node]
		walked.reserveCapacity(path.count + 1)

		for edge in path {
			guard let record = record(for: edge) else {
				return nil
			}

			let origin = direction == .outgoing ? record.source : record.target
			guard origin == slot else {
				return nil
			}

			slot = self.slot(traversing: edge, in: direction)
			walked.append(self.node(inSlot: slot))
		}

		return walked
	}

/// Reconstructs a path by walking backwards from the node it ends at.
///
/// - Parameters:
///   - source: The slot storing the node the path starts at.
///   - target: The slot storing the node the path ends at.
///   - arrival: For each slot, the edge the path arrived at it by.
///   - direction: The direction the path walks the edges in.
///
/// - Returns: The ordered edges forming the path.
///
	internal func path(from source: Int, to target: Int, arrivingBy arrival: [Edge?], in direction: EdgeDirection) -> [Edge] {
		var path: [Edge] = []
		var slot = target

		while slot != source, let edge = arrival[slot] {
			path.append(edge)
			slot = self.slot(traversing: edge, in: direction.reversed)
		}

		return path.reversed()
	}
}

extension Graph where Value: Comparable & AdditiveArithmetic {
/// The shortest path between two nodes, measured by the total value of the
/// edges walked.
///
/// This is available when the value carried by an edge is itself a weight.
///
/// - Parameters:
///   - source: The node the path starts at.
///   - target: The node the path ends at.
///   - direction: The direction to walk the edges in. Defaults to
///   ``EdgeDirection/outgoing``.
///
/// - Returns: The ordered edges forming the shortest path between the nodes,
///   or nil if no path exists.
///
	public func weightedShortestPath(from source: Node, to target: Node, in direction: EdgeDirection = .outgoing) -> [Edge]? {
		shortestPath(from: source, to: target, in: direction) {
			$0
		}
	}
}
