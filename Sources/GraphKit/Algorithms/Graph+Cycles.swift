//
//  Graph+Cycles.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// Finds a directed cycle in the graph, if one exists.
///
/// This describes why ``topologicallySorted(in:)`` was unable to order the
/// graph, and why ``isAcyclic`` is false, so that a cycle can be reported
/// rather than only detected.
///
/// ```swift
/// if let cycle = dependencies.findCycle() {
///     let nodes = dependencies.nodes(along: cycle, from: dependencies.source(of: cycle[0])!)
///     // "Material", "Texture", "Mesh", "Material"
/// }
/// ```
///
/// The edges form a closed walk, so the node the first edge leaves is the
/// same as the node the last edge arrives at. A node connected to itself
/// forms a cycle of a single edge.
///
/// Where the graph contains more than one cycle, which one is found is
/// unspecified, but is stable for a given graph.
///
/// - Returns: The ordered edges forming a cycle, or nil if the graph is
///   acyclic.
///
	public func findCycle() -> [Edge]? {
		// Each node is undiscovered, discovered and still being walked, or
		// finished. An edge arriving at a node that is still being walked has
		// closed a cycle, as that node is on the path that reached it.
		//
		let undiscovered: UInt8 = 0
		let active: UInt8 = 1
		let finished: UInt8 = 2

		var marks = [UInt8](repeating: undiscovered, count: slotCapacity)

		for origin in occupiedSlots where marks[origin] == undiscovered {
			marks[origin] = active

			var stack = [frame(for: origin, in: .outgoing)]

			while stack.isEmpty == false {
				guard let edge = stack[stack.count - 1].nextEdge() else {
					marks[stack[stack.count - 1].slot] = finished
					stack.removeLast()
					continue
				}

				let next = slot(traversing: edge, in: .outgoing)

				switch marks[next] {
					case undiscovered:
						marks[next] = active
						stack.append(frame(for: next, in: .outgoing, arrival: edge))

					case active:
						// The edge arrived back at a node still on the stack.
						// The cycle is the portion of the stack from that node
						// upwards, closed by this edge.
						//
						guard let start = stack.firstIndex(where: { $0.slot == next }) else {
							continue
						}

						var cycle = stack[(start + 1)...].compactMap(\.arrival)
						cycle.append(edge)

						return cycle

					default:
						continue
				}
			}
		}

		return nil
	}

/// Finds the path that connecting one node to another would close into a
/// cycle.
///
/// This describes why ``connect(_:to:value:at:)`` rejected a connection in a
/// graph that does not contain ``GraphOptions/allowsCycles``, so that the
/// cycle can be reported rather than only prevented.
///
/// ```swift
/// if let path = dependencies.cycle(connecting: texture, to: mesh) {
///     let nodes = dependencies.nodes(along: path, from: mesh)
///     // "Mesh", "Material", "Texture"  —  connecting Texture to Mesh closes it
/// }
/// ```
///
/// The edges returned already exist, and run from the target node back to the
/// source node. The connection being tested would close the walk, so the full
/// cycle is the source node, followed by the nodes along the path.
///
/// Connecting a node to itself closes a cycle with no intervening edges, and
/// is reported as an empty path rather than as nil.
///
/// - Parameters:
///   - source: The node the connection would leave.
///   - target: The node the connection would arrive at.
///
/// - Returns: The ordered edges leading from the target node back to the
///   source node, or nil if the connection would not close a cycle. This is
///   also nil if either node is not a member of the graph, as the connection
///   would be rejected regardless.
///
	public func cycle(connecting source: Node, to target: Node) -> [Edge]? {
		guard contains(source), contains(target) else {
			return nil
		}

		return shortestPath(from: target, to: source)
	}
}
