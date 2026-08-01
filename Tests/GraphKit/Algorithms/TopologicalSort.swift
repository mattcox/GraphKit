//
//  TopologicalSort.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Topological Sort")
struct TopologicalSortTests {
/// Tests that every node is ordered before the nodes it is connected to.
///
	@Test("Orders Dependencies")
	func ordersDependencies() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("b", to: "d")
		try graph.connect("c", to: "d")

		let sorted = try #require(graph.topologicallySorted())

		#expect(sorted.count == 4)
		#expect(sorted.first == "a")
		#expect(sorted.last == "d")

		for node in sorted {
			let index = try #require(sorted.firstIndex(of: node))

			for successor in graph.successors(of: node) {
				let successorIndex = try #require(sorted.firstIndex(of: successor))
				#expect(index < successorIndex)
			}
		}
	}

/// Tests that every node appears exactly once, including nodes that are not
/// connected to anything.
///
	@Test("Includes Isolated Nodes")
	func includesIsolatedNodes() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "isolated"], options: .acyclic)
		try graph.connect("a", to: "b")

		let sorted = try #require(graph.topologicallySorted())

		#expect(sorted.count == 3)
		#expect(Set(sorted) == ["a", "b", "isolated"])
	}

/// Tests that a graph containing a cycle cannot be ordered.
///
	@Test("Rejects Cycles")
	func rejectsCycles() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "b")

		#expect(graph.topologicallySorted() == nil)
	}

/// Tests that a node connected to itself cannot be ordered.
///
	@Test("Rejects Self Loops")
	func rejectsSelfLoops() throws {
		var graph = Graph<String, Void>(nodes: ["a"])
		try graph.connect("a", to: "a")

		#expect(graph.topologicallySorted() == nil)
	}

/// Tests that parallel edges do not prevent a graph from being ordered.
///
	@Test("Parallel Edges")
	func parallelEdges() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "b")

		#expect(graph.topologicallySorted() == ["a", "b"])
	}

/// Tests that ordering by incoming edges reverses the result.
///
	@Test("Incoming")
	func incoming() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		#expect(graph.topologicallySorted(in: .outgoing) == ["a", "b", "c"])
		#expect(graph.topologicallySorted(in: .incoming) == ["c", "b", "a"])
	}

/// Tests that an empty graph is ordered as empty, rather than as a failure.
///
	@Test("Empty")
	func empty() throws {
		let graph = Graph<String, Void>()

		#expect(graph.topologicallySorted() == [])
	}
}
