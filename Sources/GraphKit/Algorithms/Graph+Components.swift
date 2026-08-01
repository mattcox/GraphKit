//
//  Graph+Components.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// Groups the nodes in the graph into sets that can all reach one another by
/// walking the edges forwards.
///
/// A strongly connected component containing more than one node is a set of
/// nodes that are mutually reachable, which is the general form of a cycle. A
/// node that is not part of any cycle forms a component of its own, so every
/// node in the graph appears in exactly one component.
///
/// ```swift
/// let tangles = dependencies.stronglyConnectedComponents().filter {
///     $0.count > 1
/// }
/// ```
///
/// Collapsing each component into a single node produces a graph that is
/// always acyclic, so this can be used to order a graph that
/// ``topologicallySorted(in:)`` cannot. The components are returned in the
/// reverse of that order, so a component appears before every component it
/// can reach.
///
/// This is Tarjan's algorithm, and visits every node and edge once.
///
/// - Returns: The nodes in the graph, grouped into strongly connected
///   components.
///
	public func stronglyConnectedComponents() -> [[Node]] {
		// The order each node was discovered in, and the lowest order
		// reachable from it. A node whose lowest reachable order is its own is
		// the root of a component.
		//
		var discovery = [Int](repeating: -1, count: slotCapacity)
		var lowest = [Int](repeating: 0, count: slotCapacity)
		var isPending = [Bool](repeating: false, count: slotCapacity)

		var nextOrder = 0
		var pending: [Int] = []
		var components: [[Node]] = []

		for origin in occupiedSlots where discovery[origin] < 0 {
			discovery[origin] = nextOrder
			lowest[origin] = nextOrder
			nextOrder += 1

			pending.append(origin)
			isPending[origin] = true

			var stack = [frame(for: origin, in: .outgoing)]

			while stack.isEmpty == false {
				let current = stack[stack.count - 1].slot

				if let edge = stack[stack.count - 1].nextEdge() {
					let next = slot(traversing: edge, in: .outgoing)

					if discovery[next] < 0 {
						discovery[next] = nextOrder
						lowest[next] = nextOrder
						nextOrder += 1

						pending.append(next)
						isPending[next] = true

						stack.append(frame(for: next, in: .outgoing, arrival: edge))
					}
					else if isPending[next] {
						// The edge arrived back at a node that has not yet been
						// assigned to a component, so both nodes belong to the
						// same one.
						//
						lowest[current] = min(lowest[current], discovery[next])
					}

					continue
				}

				// Every edge leaving the node has been walked. If nothing
				// reachable from it was discovered earlier than it was, it is
				// the root of a component.
				//
				if lowest[current] == discovery[current] {
					var component: [Node] = []

					while let slot = pending.popLast() {
						isPending[slot] = false
						component.append(node(inSlot: slot))

						if slot == current {
							break
						}
					}

					// The component was gathered from the root outwards, so is
					// reversed to report the root first.
					//
					component.reverse()
					components.append(component)
				}

				stack.removeLast()

				if let parent = stack.last?.slot {
					lowest[parent] = min(lowest[parent], lowest[current])
				}
			}
		}

		return components
	}

/// Groups the nodes in the graph into sets that are connected to one another,
/// ignoring the direction of the edges.
///
/// Each component is an independent part of the graph, so nothing in one can
/// affect anything in another. A graph describing a single connected
/// structure has one component; a graph with no edges has one component per
/// node.
///
/// ```swift
/// // Each component can be evaluated without regard for the others.
/// for component in dependencies.connectedComponents() {
///     evaluate(component)
/// }
/// ```
///
/// - Returns: The nodes in the graph, grouped into connected components.
///
	public func connectedComponents() -> [[Node]] {
		var visited = [Bool](repeating: false, count: slotCapacity)
		var components: [[Node]] = []

		for origin in occupiedSlots where visited[origin] == false {
			components.append(component(from: origin, visited: &visited))
		}

		return components
	}

/// The nodes connected to the provided node, ignoring the direction of the
/// edges.
///
/// The node itself is always included, so a node connected to nothing forms a
/// component of its own.
///
/// - Parameters:
///   - node: The node to describe the component of.
///
/// - Returns: The nodes in the same component as the node, or an empty
///   collection if the node is not a member of the graph.
///
	public func component(containing node: Node) -> [Node] {
		guard let origin = nodeSlots[node] else {
			return []
		}

		var visited = [Bool](repeating: false, count: slotCapacity)
		return component(from: origin, visited: &visited)
	}

/// Gathers the nodes connected to the node in the provided slot, ignoring the
/// direction of the edges.
///
/// - Parameters:
///   - origin: The slot to walk from. This must store a node that has not yet
///   been visited.
///   - visited: For each node slot, whether the node it stores has already
///   been gathered into a component. This is updated as the walk proceeds, so
///   that a graph can be split into components without revisiting a node.
///
/// - Returns: The nodes in the same component as the node in the slot.
///
	private func component(from origin: Int, visited: inout [Bool]) -> [Node] {
		var component: [Node] = []
		var pending = [origin]

		visited[origin] = true

		var front = 0
		while front < pending.count {
			let slot = pending[front]
			front += 1

			component.append(node(inSlot: slot))

			for direction in EdgeDirection.allCases {
				for edge in edges(inSlot: slot, in: direction) {
					let next = self.slot(traversing: edge, in: direction)

					if visited[next] == false {
						visited[next] = true
						pending.append(next)
					}
				}
			}
		}

		return component
	}
}
