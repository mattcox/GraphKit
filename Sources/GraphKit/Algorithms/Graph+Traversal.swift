//
//  Graph+Traversal.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// A lazy sequence visiting the nodes reachable from a starting node.
///
/// The traversal holds the graph it was created from, so it is unaffected by
/// any mutation applied to the graph afterwards.
///
	public struct Traversal {
	/// The graph being walked, captured when the traversal was created.
	///
		internal let graph: Graph

	/// The slot storing the node to start walking from, or nil if the node
	/// is not a member of the graph.
	///
		internal let origin: Int?

	/// The order to visit the nodes in.
	///
		internal let order: TraversalOrder

	/// The direction to walk the edges in.
	///
		internal let direction: EdgeDirection

	/// Initialize a traversal describing a walk of the graph.
	///
	/// - Parameters:
	///   - graph: The graph to walk.
	///   - origin: The slot storing the node to start walking from, or nil
	///   to describe an empty walk.
	///   - order: The order to visit the nodes in.
	///   - direction: The direction to walk the edges in.
	///
		internal init(graph: Graph, origin: Int?, order: TraversalOrder, direction: EdgeDirection) {
			self.graph = graph
			self.origin = origin
			self.order = order
			self.direction = direction
		}
	}
}

extension Graph.Traversal: Sequence {
/// An iterator walking the nodes reachable from the starting node.
///
	public struct Iterator: IteratorProtocol {
	/// The graph being walked.
	///
		internal let graph: Graph

	/// The order to visit the nodes in.
	///
		internal let order: TraversalOrder

	/// The direction to walk the edges in.
	///
		internal let direction: EdgeDirection

	/// For each node slot, whether the node it stores has been visited.
	///
	/// This is addressed by slot rather than by node identifier, so that
	/// testing whether a node has been visited never needs to hash.
	///
		internal var visited: [Bool]

	/// The slots storing the nodes that are waiting to be visited.
	///
	/// This is used as a queue when visiting breadth first, and as a stack
	/// when visiting depth first.
	///
		internal var pending: [Int]

	/// The offset of the front of the queue, used when visiting breadth
	/// first.
	///
	/// The queue is drained by advancing the offset rather than by removing
	/// from the front, so that dequeuing is a constant time operation.
	///
		internal var front: Int

	/// Initialize an iterator walking the graph from the provided slot.
	///
	/// - Parameters:
	///   - graph: The graph to walk.
	///   - origin: The slot storing the node to start walking from, or nil
	///   to describe an empty walk.
	///   - order: The order to visit the nodes in.
	///   - direction: The direction to walk the edges in.
	///
		internal init(graph: Graph, origin: Int?, order: TraversalOrder, direction: EdgeDirection) {
			self.graph = graph
			self.order = order
			self.direction = direction
			self.visited = [Bool](repeating: false, count: graph.slotCapacity)
			self.pending = []
			self.front = 0

			if let origin {
				pending.append(origin)

				// A breadth first traversal marks a node as visited when it is
				// enqueued, so that it is never enqueued twice. A depth first
				// traversal marks a node when it is visited instead, as the
				// same node may legitimately be stacked more than once before
				// the first of them is reached.
				//
				if order == .breadthFirst {
					visited[origin] = true
				}
			}
		}

	/// Advances to the next node in the walk.
	///
	/// - Returns: The next node reachable from the starting node, or nil
	///   once every reachable node has been visited.
	///
		public mutating func next() -> Node? {
			guard let slot = nextSlot() else {
				return nil
			}

			let edges = graph.edges(inSlot: slot, in: direction)

			switch order {
				case .breadthFirst:
					for edge in edges {
						let next = graph.slot(traversing: edge, in: direction)
						if visited[next] == false {
							visited[next] = true
							pending.append(next)
						}
					}

				case .depthFirst:
					// The edges are stacked in reverse, so that the first edge
					// connected to the node is the first one walked.
					//
					for edge in edges.reversed() {
						let next = graph.slot(traversing: edge, in: direction)
						if visited[next] == false {
							pending.append(next)
						}
					}
			}

			return graph.node(inSlot: slot)
		}

	/// Removes the next unvisited node from the pending collection.
	///
	/// - Returns: The slot storing the next node to visit, or nil if the
	///   traversal is complete.
	///
		internal mutating func nextSlot() -> Int? {
			switch order {
				case .breadthFirst:
					guard front < pending.count else {
						return nil
					}

					let slot = pending[front]
					front += 1
					return slot

				case .depthFirst:
					while let slot = pending.popLast() {
						if visited[slot] == false {
							visited[slot] = true
							return slot
						}
					}

					return nil
			}
		}
	}

/// Creates an iterator walking the graph from the starting node.
///
/// Each iterator carries its own working storage, so a traversal can be
/// walked more than once, and more than once at a time.
///
/// - Returns: An iterator walking the nodes reachable from the starting node.
///
	public func makeIterator() -> Iterator {
		Iterator(graph: graph, origin: origin, order: order, direction: direction)
	}
}

extension Graph.Traversal: Sendable where Node: Sendable, Value: Sendable {

}

extension Graph {
/// Walks the graph from the provided node, visiting every node reachable from
/// it exactly once.
///
/// The traversal is lazy, so it can be abandoned part way through without
/// walking the remainder of the graph.
///
/// ```swift
/// // The first material downstream of this item that needs rebuilding.
/// let stale = graph.traversal(from: item).first { needsRebuilding($0) }
/// ```
///
/// The starting node is the first node visited. If it is not a member of the
/// graph, the traversal is empty.
///
/// - Parameters:
///   - node: The node to walk from.
///   - order: The order to visit the nodes in. Defaults to
///   ``TraversalOrder/breadthFirst``.
///   - direction: The direction to walk the edges in. Walking outgoing edges
///   visits the nodes downstream of the starting node, and walking incoming
///   edges visits those upstream of it. Defaults to
///   ``EdgeDirection/outgoing``.
///
/// - Returns: A lazy sequence visiting the nodes reachable from the node.
///
	public func traversal(from node: Node, order: TraversalOrder = .breadthFirst, in direction: EdgeDirection = .outgoing) -> Traversal {
		Traversal(graph: self, origin: nodeSlots[node], order: order, direction: direction)
	}
}
