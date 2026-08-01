//
//  Graph+Layering.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// Groups the nodes in the graph into layers, so that every edge advances by
/// at least one layer.
///
/// Where ``topologicallySorted(in:)`` flattens the graph into a single order,
/// this preserves the fact that some nodes are independent of one another.
/// Nodes sharing a layer are never connected, directly or indirectly.
///
/// ```swift
/// // Lay a node graph out in columns.
/// for (column, layer) in dependencies.topologicalLayers()!.enumerated() {
///     for (row, node) in layer.enumerated() {
///         position[node] = Point(x: column * 220, y: row * 90)
///     }
/// }
/// ```
///
/// Because a layer contains no internal dependencies, everything in it can be
/// evaluated at once, and the number of layers is the length of the longest
/// chain in the graph. That chain is the critical path, and bounds how few
/// sequential steps the graph can be evaluated in however much of it is
/// evaluated in parallel.
///
/// ```swift
/// for layer in dependencies.topologicalLayers()! {
///     await withTaskGroup { group in
///         for node in layer {
///             group.addTask { evaluate(node) }
///         }
///     }
/// }
/// ```
///
/// Each node is placed by the longest path leading to it rather than the
/// shortest, which is what guarantees that no edge runs sideways within a
/// layer. Within a layer, nodes are ordered consistently with
/// ``topologicallySorted(in:)``.
///
/// A graph containing a cycle cannot be layered, for the same reason it
/// cannot be ordered.
///
/// - Parameters:
///   - direction: The direction to layer the nodes in. Layering by outgoing
///   edges places each node before its successors. Defaults to
///   ``EdgeDirection/outgoing``.
///   - alignment: Where to place a node that its dependencies do not pin to a
///   single layer. Defaults to ``LayerAlignment/earliest``.
///
/// - Returns: The nodes in the graph, grouped into layers, or nil if the
///   graph contains a cycle. An empty graph produces no layers.
///
	public func topologicalLayers(in direction: EdgeDirection = .outgoing, alignment: LayerAlignment = .earliest) -> [[Node]]? {
		guard isEmpty == false else {
			return []
		}

		// Placing a node as late as possible is the same as placing it as
		// early as possible in the opposite direction, and then counting the
		// layers from the far end.
		//
		let walk = alignment == .earliest ? direction : direction.reversed

		guard let layering = longestPathLayering(in: walk) else {
			return nil
		}

		var layers = [[Node]](repeating: [], count: layering.depth + 1)

		// The order the nodes were resolved in is a valid ordering for the
		// direction that was walked, so reversing it produces one for the
		// direction that was asked for.
		//
		var ordered = layering.order
		if alignment == .latest {
			ordered.reverse()
		}

		for slot in ordered {
			let layer = alignment == .earliest ? layering.assignment[slot] : layering.depth - layering.assignment[slot]
			layers[layer].append(node(inSlot: slot))
		}

		return layers
	}

/// The layer a single node occupies.
///
/// This resolves the layering of the whole graph in order to place one node,
/// so laying out every node is better served by ``topologicalLayers(in:alignment:)``.
///
/// - Parameters:
///   - node: The node to place.
///   - direction: The direction to layer the nodes in. Defaults to
///   ``EdgeDirection/outgoing``.
///   - alignment: Where to place a node that its dependencies do not pin to a
///   single layer. Defaults to ``LayerAlignment/earliest``.
///
/// - Returns: The layer the node occupies, or nil if the node is not a member
///   of the graph, or the graph contains a cycle.
///
	public func layer(of node: Node, in direction: EdgeDirection = .outgoing, alignment: LayerAlignment = .earliest) -> Int? {
		guard let slot = nodeSlots[node] else {
			return nil
		}

		let walk = alignment == .earliest ? direction : direction.reversed

		guard let layering = longestPathLayering(in: walk) else {
			return nil
		}

		return alignment == .earliest ? layering.assignment[slot] : layering.depth - layering.assignment[slot]
	}

/// Assigns each node to the layer described by the longest path leading to
/// it.
///
/// This resolves the nodes in the same order as
/// ``topologicallySorted(in:)``, so that the layer of every node a node
/// depends upon is known by the time that node is reached.
///
/// - Parameters:
///   - direction: The direction to layer the nodes in.
///
/// - Returns: For each node slot, the layer the node it stores occupies,
///   along with the order the nodes were resolved in and the index of the
///   last layer. This is nil if the graph contains a cycle.
///
	private func longestPathLayering(in direction: EdgeDirection) -> (assignment: [Int], order: [Int], depth: Int)? {
		let incoming = direction.reversed

		// The number of edges arriving at each node that have not yet been
		// resolved. A node can only be placed once every node before it has
		// been, as its layer is one beyond the last of them.
		//
		var remaining = [Int](repeating: 0, count: slotCapacity)
		var assignment = [Int](repeating: 0, count: slotCapacity)
		var ready: [Int] = []

		for slot in nodeRecords.indices where nodeRecords[slot] != nil {
			let count = edges(inSlot: slot, in: incoming).count
			remaining[slot] = count

			if count == 0 {
				ready.append(slot)
			}
		}

		var order: [Int] = []
		order.reserveCapacity(nodeCount)

		var depth = 0

		var front = 0
		while front < ready.count {
			let slot = ready[front]
			front += 1

			// Every node before this one has been placed, so its layer is now
			// final.
			//
			order.append(slot)
			depth = max(depth, assignment[slot])

			for edge in edges(inSlot: slot, in: direction) {
				let next = self.slot(traversing: edge, in: direction)

				assignment[next] = max(assignment[next], assignment[slot] + 1)

				remaining[next] -= 1
				if remaining[next] == 0 {
					ready.append(next)
				}
			}
		}

		// Any node that was never made ready is part of a cycle, or is
		// downstream of one.
		//
		guard order.count == nodeCount else {
			return nil
		}

		return (assignment, order, depth)
	}
}
