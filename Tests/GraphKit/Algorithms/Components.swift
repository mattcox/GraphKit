//
//  Components.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Components")
struct ComponentTests {
/// Tests that every node in an acyclic graph forms a component of its own.
///
	@Test("Acyclic Is All Singletons")
	func acyclicIsAllSingletons() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		let components = graph.stronglyConnectedComponents()

		#expect(components.count == 3)
		#expect(components.allSatisfy { $0.count == 1 })
	}

/// Tests that mutually reachable nodes are grouped together, and that nodes
/// outside the cycle are not.
///
	@Test("Groups Mutually Reachable Nodes")
	func groupsMutuallyReachableNodes() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "before", "after"])

		try graph.connect("before", to: "a")
		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "a")
		try graph.connect("c", to: "after")

		let components = graph.stronglyConnectedComponents()
		let tangles = components.filter {
			$0.count > 1
		}

		#expect(components.count == 3)
		#expect(tangles.count == 1)
		#expect(Set(tangles[0]) == ["a", "b", "c"])
	}

/// Tests that every node appears in exactly one component.
///
	@Test("Partitions Every Node")
	func partitionsEveryNode() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d", "isolated"])

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "a")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "d")

		let components = graph.stronglyConnectedComponents()
		let all = components.flatMap { $0 }

		#expect(all.count == graph.nodeCount)
		#expect(Set(all) == Set(graph.nodes))
	}

/// Tests that a node connected to itself forms a component containing only
/// itself, as it does when it is not connected at all.
///
	@Test("Self Loop")
	func selfLoop() throws {
		var graph = Graph<String, Void>(nodes: ["a"])
		try graph.connect("a", to: "a")

		#expect(graph.stronglyConnectedComponents() == [["a"]])
	}

/// Tests that the components are ordered so that each appears before every
/// component it can reach.
///
	@Test("Reverse Topological Order")
	func reverseTopologicalOrder() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		// Collapsing the components produces an acyclic graph, which this
		// ordering reverses.
		//
		let components = graph.stronglyConnectedComponents()

		#expect(components.map(\.first) == ["c", "b", "a"])
	}

/// Tests that a cyclic graph that cannot be ordered can still be ordered once
/// its components have been collapsed.
///
	@Test("Orders A Cyclic Graph")
	func ordersACyclicGraph() throws {
		var graph = Graph<String, Void>(nodes: ["input", "a", "b", "output"])

		try graph.connect("input", to: "a")
		try graph.connect("a", to: "b")
		try graph.connect("b", to: "a")
		try graph.connect("b", to: "output")

		#expect(graph.topologicallySorted() == nil)

		let ordered = graph.stronglyConnectedComponents().reversed().map {
			$0.sorted()
		}

		#expect(Array(ordered) == [["input"], ["a", "b"], ["output"]])
	}

/// Tests that a large cycle is grouped without exhausting the stack, as the
/// walk is iterative rather than recursive.
///
	@Test("Deep Cycle")
	func deepCycle() throws {
		let nodes = (0..<5000).map { "\($0)" }
		var graph = Graph<String, Void>(nodes: nodes)

		for index in 1..<nodes.count {
			try graph.connect(nodes[index - 1], to: nodes[index])
		}
		try graph.connect(nodes[nodes.count - 1], to: nodes[0])

		let components = graph.stronglyConnectedComponents()

		#expect(components.count == 1)
		#expect(components[0].count == nodes.count)
		#expect(graph.findCycle()?.count == nodes.count)
	}
}

@Suite("Connected Components")
struct ConnectedComponentTests {
/// Tests that parts of the graph that cannot reach one another in either
/// direction are reported separately.
///
	@Test("Splits Independent Parts")
	func splitsIndependentParts() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d", "isolated"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("c", to: "d")

		let components = graph.connectedComponents()

		#expect(components.count == 3)
		#expect(Set(components.map { Set($0) }) == [["a", "b"], ["c", "d"], ["isolated"]])
	}

/// Tests that direction is ignored, so nodes sharing a target are in the same
/// component.
///
	@Test("Ignores Direction")
	func ignoresDirection() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "target"], options: .acyclic)

		try graph.connect("a", to: "target")
		try graph.connect("b", to: "target")

		let components = graph.connectedComponents()

		#expect(components.count == 1)
		#expect(Set(components[0]) == ["a", "b", "target"])

		// "a" cannot reach "b" by walking forwards, but they are connected.
		//
		#expect(graph.reaches("b", from: "a") == false)
	}

/// Tests that a graph with no edges reports one component per node.
///
	@Test("No Edges")
	func noEdges() throws {
		let graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		#expect(graph.connectedComponents().count == 3)
	}

/// Tests that the component containing a specific node can be described.
///
	@Test("Component Containing")
	func componentContaining() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "isolated"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		#expect(Set(graph.component(containing: "c")) == ["a", "b", "c"])
		#expect(graph.component(containing: "isolated") == ["isolated"])
		#expect(graph.component(containing: "unknown").isEmpty)
	}

/// Tests that an empty graph reports no components.
///
	@Test("Empty")
	func empty() throws {
		let graph = Graph<String, Void>()

		#expect(graph.connectedComponents().isEmpty)
		#expect(graph.stronglyConnectedComponents().isEmpty)
	}
}
