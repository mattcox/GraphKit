//
//  ShortestPath.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Shortest Path")
struct ShortestPathTests {
/// Tests that the path found is the one walking the fewest edges.
///
	@Test("Fewest Edges")
	func fewestEdges() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "d")
		try graph.connect("a", to: "d")

		let path = try #require(graph.shortestPath(from: "a", to: "d"))

		#expect(path.count == 1)
		#expect(graph.nodes(along: path, from: "a") == ["a", "d"])
	}

/// Tests that a path between unconnected nodes is absent, rather than empty.
///
	@Test("Unreachable")
	func unreachable() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "isolated"], options: .acyclic)
		try graph.connect("a", to: "b")

		#expect(graph.shortestPath(from: "a", to: "isolated") == nil)
		#expect(graph.shortestPath(from: "b", to: "a") == nil)
		#expect(graph.shortestPath(from: "a", to: "unknown") == nil)
	}

/// Tests that a path from a node to itself is empty.
///
	@Test("Same Node")
	func sameNode() throws {
		let graph = Graph<String, Void>(nodes: ["a"])

		#expect(graph.shortestPath(from: "a", to: "a") == [])
		#expect(graph.nodes(along: [], from: "a") == ["a"])
	}

/// Tests that a path can be walked backwards.
///
	@Test("Incoming")
	func incoming() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		let path = try #require(graph.shortestPath(from: "c", to: "a", in: .incoming))

		#expect(path.count == 2)
		#expect(graph.nodes(along: path, from: "c", in: .incoming) == ["c", "b", "a"])
	}

/// Tests that a weighted path prefers a longer walk with a lower total
/// weight.
///
	@Test("Weighted")
	func weighted() throws {
		var graph = Graph<String, Double>(nodes: ["a", "b", "c", "d"], options: .acyclic)

		try graph.connect("a", to: "d", value: 100.0)
		try graph.connect("a", to: "b", value: 1.0)
		try graph.connect("b", to: "c", value: 1.0)
		try graph.connect("c", to: "d", value: 1.0)

		let unweighted = try #require(graph.shortestPath(from: "a", to: "d"))
		#expect(graph.nodes(along: unweighted, from: "a") == ["a", "d"])

		let weighted = try #require(graph.weightedShortestPath(from: "a", to: "d"))
		#expect(graph.nodes(along: weighted, from: "a") == ["a", "b", "c", "d"])
	}

/// Tests that a weight can be derived from the value carried by an edge.
///
	@Test("Derived Weight")
	func derivedWeight() throws {
		struct Link {
			var kilometres: Double
		}

		var graph = Graph<String, Link>(nodes: ["London", "Paris", "Rome"], options: .acyclic)

		try graph.connect("London", to: "Rome", value: Link(kilometres: 1800.0))
		try graph.connect("London", to: "Paris", value: Link(kilometres: 344.0))
		try graph.connect("Paris", to: "Rome", value: Link(kilometres: 1100.0))

		let route = try #require(graph.shortestPath(from: "London", to: "Rome") { $0.kilometres })

		#expect(graph.nodes(along: route, from: "London") == ["London", "Paris", "Rome"])
	}

/// Tests that a weighted path improves upon a route that was settled early.
///
	@Test("Weighted Relaxation")
	func weightedRelaxation() throws {
		var graph = Graph<String, Int>(nodes: ["a", "b", "c", "d", "e"], options: .acyclic)

		try graph.connect("a", to: "b", value: 1)
		try graph.connect("a", to: "c", value: 5)
		try graph.connect("b", to: "c", value: 1)
		try graph.connect("c", to: "d", value: 1)
		try graph.connect("b", to: "e", value: 20)
		try graph.connect("e", to: "d", value: 1)

		let path = try #require(graph.weightedShortestPath(from: "a", to: "d"))

		#expect(graph.nodes(along: path, from: "a") == ["a", "b", "c", "d"])
	}

/// Tests that a weighted path in a cyclic graph terminates, and finds the
/// shorter of the two routes.
///
	@Test("Weighted Cycle")
	func weightedCycle() throws {
		var graph = Graph<String, Int>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b", value: 1)
		try graph.connect("b", to: "c", value: 1)
		try graph.connect("c", to: "a", value: 1)
		try graph.connect("a", to: "c", value: 5)

		let path = try #require(graph.weightedShortestPath(from: "a", to: "c"))

		#expect(graph.nodes(along: path, from: "a") == ["a", "b", "c"])
	}

/// Tests that walking a path that is not connected to the starting node is
/// reported, rather than producing a nonsensical result.
///
	@Test("Disconnected Walk")
	func disconnectedWalk() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		let unrelated = try graph.connect("b", to: "c")

		#expect(graph.nodes(along: [unrelated], from: "a") == nil)
		#expect(graph.nodes(along: [], from: "unknown") == nil)
	}
}
