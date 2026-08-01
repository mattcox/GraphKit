//
//  Graph+DepthFirst.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// A frame on the explicit stack used to walk the graph depth first.
///
/// The algorithms that need to observe a node both on the way down and on the
/// way back up cannot use ``Traversal``, which only reports a node once. They
/// drive an explicit stack of frames instead, so that the walk is iterative
/// rather than recursive, and the depth it can reach is bounded by the heap
/// rather than by the call stack.
///
	internal struct DepthFirstFrame {
	/// The slot storing the node the frame describes.
	///
		internal var slot: Int

	/// The ordered edges connected to the node, in the direction being
	/// walked.
	///
	/// These are captured when the frame is pushed, so that the walk is not
	/// disturbed by anything the caller does to the graph.
	///
		internal var edges: [Edge]

	/// The offset of the next edge to walk.
	///
		internal var offset: Int

	/// The edge the walk arrived at the node by, or nil if the node is the
	/// one the walk started from.
	///
	/// Following this from the top of the stack back down to a frame
	/// describes the path currently being walked.
	///
		internal var arrival: Edge?

	/// Initialize a frame describing a node that has just been discovered.
	///
	/// - Parameters:
	///   - slot: The slot storing the node the frame describes.
	///   - edges: The ordered edges connected to the node.
	///   - arrival: The edge the walk arrived at the node by, or nil if the
	///   node is the one the walk started from.
	///
		internal init(slot: Int, edges: [Edge], arrival: Edge? = nil) {
			self.slot = slot
			self.edges = edges
			self.offset = 0
			self.arrival = arrival
		}

	/// Advances to the next edge leaving the node.
	///
	/// - Returns: The next edge to walk, or nil once every edge connected to
	///   the node has been walked.
	///
		internal mutating func nextEdge() -> Edge? {
			guard offset < edges.count else {
				return nil
			}

			let edge = edges[offset]
			offset += 1

			return edge
		}
	}

/// Creates a frame describing the node in the provided slot.
///
/// - Parameters:
///   - slot: The slot storing the node the frame describes.
///   - direction: The direction the walk is being made in.
///   - arrival: The edge the walk arrived at the node by, or nil if the node
///   is the one the walk started from.
///
/// - Returns: A frame ready to be pushed onto the stack.
///
	internal func frame(for slot: Int, in direction: EdgeDirection, arrival: Edge? = nil) -> DepthFirstFrame {
		DepthFirstFrame(slot: slot, edges: edges(inSlot: slot, in: direction), arrival: arrival)
	}

/// The slots storing every node in the graph, in the order they are stored.
///
/// The algorithms that visit the whole graph start from each of these in
/// turn, so that nodes that cannot be reached from one another are still
/// visited.
///
	internal var occupiedSlots: [Int] {
		nodeRecords.indices.filter {
			nodeRecords[$0] != nil
		}
	}
}
