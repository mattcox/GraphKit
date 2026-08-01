//
//  Reachability.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Reachability")
struct ReachabilityTests {
/// Tests that reachability follows the direction of the edges.
///
	@Test("Reaches")
	func reaches() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "isolated"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		#expect(graph.reaches("c", from: "a"))
		#expect(graph.reaches("a", from: "c") == false)
		#expect(graph.reaches("a", from: "c", in: .incoming))
		#expect(graph.reaches("isolated", from: "a") == false)
		#expect(graph.reaches("a", from: "a"))
		#expect(graph.reaches("unknown", from: "a") == false)
	}

/// Tests that the nodes reachable from a node exclude the node itself, unless
/// a walk returns to it.
///
	@Test("Reachable Nodes")
	func reachableNodes() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		#expect(graph.nodes(reachableFrom: "a") == ["b", "c"])
		#expect(graph.nodes(reachableFrom: "c").isEmpty)
		#expect(graph.nodes(reachableFrom: "c", in: .incoming) == ["b", "a"])
	}

/// Tests that a node within a cycle is reachable from itself.
///
	@Test("Reachable Through Cycle")
	func reachableThroughCycle() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "a")

		#expect(graph.reaches("a", from: "a"))
		#expect(graph.nodes(reachableFrom: "a") == ["b", "c", "a"])
	}

/// Tests that a node connected to itself is reachable from itself.
///
	@Test("Reachable Through Self Loop")
	func reachableThroughSelfLoop() throws {
		var graph = Graph<String, Void>(nodes: ["a"])
		try graph.connect("a", to: "a")

		#expect(graph.nodes(reachableFrom: "a") == ["a"])
	}

/// Tests that a graph is reported as acyclic only when it contains no cycle.
///
	@Test("Is Acyclic")
	func isAcyclic() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		#expect(graph.isAcyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		#expect(graph.isAcyclic)

		let closing = try graph.connect("c", to: "a")
		#expect(graph.isAcyclic == false)

		try graph.disconnect(closing)
		#expect(graph.isAcyclic)

		try graph.connect("a", to: "a")
		#expect(graph.isAcyclic == false)
	}
}
