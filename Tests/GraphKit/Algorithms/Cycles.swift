//
//  Cycles.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Cycles")
struct CycleTests {
/// Tests that an acyclic graph reports no cycle.
///
	@Test("Acyclic")
	func acyclic() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("b", to: "d")
		try graph.connect("c", to: "d")

		#expect(graph.findCycle() == nil)
	}

/// Tests that an empty graph reports no cycle.
///
	@Test("Empty")
	func empty() throws {
		let graph = Graph<String, Void>()

		#expect(graph.findCycle() == nil)
	}

/// Tests that a cycle is reported as a closed walk, starting and ending at
/// the same node.
///
	@Test("Finds Cycle")
	func findsCycle() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "a")

		let cycle = try #require(graph.findCycle())
		let origin = try #require(graph.source(of: cycle[0]))
		let nodes = try #require(graph.nodes(along: cycle, from: origin))

		#expect(cycle.count == 3)
		#expect(nodes == ["a", "b", "c", "a"])
	}

/// Tests that a cycle is found when it is not reachable from the node the
/// walk starts at.
///
	@Test("Finds Detached Cycle")
	func findsDetachedCycle() throws {
		var graph = Graph<String, Void>(nodes: ["root", "a", "b"])

		// The cycle is in a part of the graph that "root" cannot reach.
		//
		try graph.connect("a", to: "b")
		try graph.connect("b", to: "a")

		let cycle = try #require(graph.findCycle())
		let origin = try #require(graph.source(of: cycle[0]))
		let nodes = try #require(graph.nodes(along: cycle, from: origin))

		#expect(cycle.count == 2)
		#expect(nodes.first == nodes.last)
		#expect(Set(nodes) == ["a", "b"])
	}

/// Tests that a node connected to itself forms a cycle of a single edge.
///
	@Test("Finds Self Loop")
	func findsSelfLoop() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])

		try graph.connect("a", to: "b")
		let loop = try graph.connect("b", to: "b")

		#expect(graph.findCycle() == [loop])
	}

/// Tests that a cycle is only reported when the walk closes, and not when two
/// branches merge.
///
	@Test("Ignores Merging Branches")
	func ignoresMergingBranches() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d", "e"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("a", to: "d")
		try graph.connect("d", to: "c")
		try graph.connect("c", to: "e")

		#expect(graph.findCycle() == nil)
		#expect(graph.isAcyclic)
	}

/// Tests that a cycle is reported exactly when the graph cannot be ordered.
///
	@Test("Agrees With Topological Sort")
	func agreesWithTopologicalSort() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		#expect(graph.findCycle() == nil)
		#expect(graph.topologicallySorted() != nil)

		let closing = try graph.connect("c", to: "a")

		#expect(graph.findCycle() != nil)
		#expect(graph.topologicallySorted() == nil)

		try graph.disconnect(closing)

		#expect(graph.findCycle() == nil)
		#expect(graph.topologicallySorted() != nil)
	}

/// Tests that the path a rejected connection would close is reported.
///
	@Test("Cycle A Connection Would Close")
	func cycleAConnectionWouldClose() throws {
		var graph = Graph<String, Void>(nodes: ["mesh", "material", "texture"], options: .acyclic)

		try graph.connect("mesh", to: "material")
		try graph.connect("material", to: "texture")

		#expect(throws: GraphError.notAllowed(what: GraphError.cycle)) {
			try graph.connect("texture", to: "mesh")
		}

		let path = try #require(graph.cycle(connecting: "texture", to: "mesh"))
		let nodes = try #require(graph.nodes(along: path, from: "mesh"))

		#expect(nodes == ["mesh", "material", "texture"])
	}

/// Tests that a connection that would not close a cycle is reported as such.
///
	@Test("Connection Without Cycle")
	func connectionWithoutCycle() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")

		#expect(graph.cycle(connecting: "b", to: "c") == nil)
		#expect(graph.cycle(connecting: "a", to: "unknown") == nil)
		#expect(graph.cycle(connecting: "unknown", to: "a") == nil)
	}

/// Tests that connecting a node to itself is reported as closing a cycle with
/// no intervening edges.
///
	@Test("Self Connection")
	func selfConnection() throws {
		let graph = Graph<String, Void>(nodes: ["a"], options: .acyclic)

		#expect(graph.cycle(connecting: "a", to: "a") == [])
	}

/// Tests that the reported cycle agrees with the constraint that rejected the
/// connection, and with the cheaper test that only detects one.
///
	@Test("Agrees With Connect")
	func agreesWithConnect() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "d")

		for source in graph.nodes {
			for target in graph.nodes where source != target {
				let predicted = graph.cycle(connecting: source, to: target) != nil

				var copy = graph
				var rejected = false
				do {
					try copy.connect(source, to: target)
				}
				catch {
					rejected = error == GraphError.notAllowed(what: GraphError.cycle)
				}

				#expect(predicted == rejected)
				#expect(predicted == graph.wouldCreateCycle(connecting: source, to: target))
			}
		}
	}

/// Tests that describing a cycle and detecting one agree, including where a
/// node would be connected to itself.
///
	@Test("Agrees With Detection")
	func agreesWithDetection() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		for source in graph.nodes {
			for target in graph.nodes {
				let described = graph.cycle(connecting: source, to: target) != nil
				let detected = graph.wouldCreateCycle(connecting: source, to: target)

				#expect(described == detected)
			}
		}
	}
}
