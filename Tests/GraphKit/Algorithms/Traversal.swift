//
//  Traversal.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Traversal")
struct TraversalTests {
/// Builds a graph shaped as a binary tree, three levels deep.
///
/// ```
///        a
///      /   \
///     b     c
///    / \   / \
///   d   e f   g
/// ```
///
	private func tree() throws -> Graph<String, Void> {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d", "e", "f", "g"], options: .tree)

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("b", to: "d")
		try graph.connect("b", to: "e")
		try graph.connect("c", to: "f")
		try graph.connect("c", to: "g")

		return graph
	}

/// Tests that a breadth first traversal visits every node at one level before
/// descending to the next.
///
	@Test("Breadth First")
	func breadthFirst() throws {
		let graph = try tree()
		let visited = Array(graph.traversal(from: "a", order: .breadthFirst))

		#expect(visited == ["a", "b", "c", "d", "e", "f", "g"])
	}

/// Tests that a depth first traversal walks each branch in full before moving
/// on to the next, and respects the ordering of the edges.
///
	@Test("Depth First")
	func depthFirst() throws {
		let graph = try tree()
		let visited = Array(graph.traversal(from: "a", order: .depthFirst))

		#expect(visited == ["a", "b", "d", "e", "c", "f", "g"])
	}

/// Tests that a traversal reflects the ordering of the edges, and follows it
/// when the ordering is changed.
///
	@Test("Follows Edge Order")
	func followsEdgeOrder() throws {
		var graph = try tree()

		let edge = try #require(graph.edge(from: "a", to: "c"))
		try graph.move(edge, to: .start, in: .outgoing)

		#expect(Array(graph.traversal(from: "a", order: .breadthFirst)) == ["a", "c", "b", "f", "g", "d", "e"])
		#expect(Array(graph.traversal(from: "a", order: .depthFirst)) == ["a", "c", "f", "g", "b", "d", "e"])
	}

/// Tests that a traversal can walk the graph backwards.
///
	@Test("Incoming")
	func incoming() throws {
		let graph = try tree()
		let visited = Array(graph.traversal(from: "d", in: .incoming))

		#expect(visited == ["d", "b", "a"])
	}

/// Tests that a node reachable by more than one path is visited exactly once.
///
	@Test("Visits Once")
	func visitsOnce() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("b", to: "d")
		try graph.connect("c", to: "d")

		#expect(Array(graph.traversal(from: "a", order: .breadthFirst)) == ["a", "b", "c", "d"])
		#expect(Array(graph.traversal(from: "a", order: .depthFirst)) == ["a", "b", "d", "c"])
	}

/// Tests that a traversal of a cyclic graph terminates.
///
	@Test("Cycle Terminates")
	func cycleTerminates() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "a")
		try graph.connect("a", to: "a")

		#expect(Array(graph.traversal(from: "a", order: .breadthFirst)) == ["a", "b", "c"])
		#expect(Array(graph.traversal(from: "a", order: .depthFirst)) == ["a", "b", "c"])
	}

/// Tests that a traversal from a node that is not a member of the graph is
/// empty.
///
	@Test("Unknown Node")
	func unknownNode() throws {
		let graph = try tree()

		#expect(Array(graph.traversal(from: "unknown")).isEmpty)
	}

/// Tests that a traversal is lazy, and can be abandoned part way through.
///
	@Test("Lazy")
	func lazy() throws {
		let graph = try tree()
		let found = graph.traversal(from: "a", order: .depthFirst).first {
			$0 == "d"
		}

		#expect(found == "d")
	}

/// Tests that a traversal holds the graph it was created from, and is
/// unaffected by any mutation applied afterwards.
///
	@Test("Snapshot")
	func snapshot() throws {
		var graph = try tree()
		let traversal = graph.traversal(from: "a")

		graph.removeAll()

		#expect(Array(traversal) == ["a", "b", "c", "d", "e", "f", "g"])
		#expect(graph.isEmpty)
	}
}
