//
//  Layering.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Layering")
struct LayeringTests {
/// Builds a graph describing a small material pipeline.
///
/// ```
/// texture ─┐
///          ├─→ material ─→ mesh ─→ output
/// shader  ─┘
/// ```
///
	private func pipeline() throws -> Graph<String, Void> {
		var graph = Graph<String, Void>(nodes: ["texture", "shader", "material", "mesh", "output"], options: .acyclic)

		try graph.connect("texture", to: "material")
		try graph.connect("shader", to: "material")
		try graph.connect("material", to: "mesh")
		try graph.connect("mesh", to: "output")

		return graph
	}

/// Tests that independent nodes share a layer, and that the layers follow the
/// direction of the edges.
///
	@Test("Groups Independent Nodes")
	func groupsIndependentNodes() throws {
		let graph = try pipeline()
		let layers = try #require(graph.topologicalLayers())

		#expect(layers.count == 4)
		#expect(Set(layers[0]) == ["texture", "shader"])
		#expect(layers[1] == ["material"])
		#expect(layers[2] == ["mesh"])
		#expect(layers[3] == ["output"])
	}

/// Tests that a node is placed by the longest path leading to it, rather than
/// the shortest.
///
/// Placing by the shortest path would put "b" and "c" in the same layer, and
/// the edge between them would run sideways within it.
///
	@Test("Uses Longest Path")
	func usesLongestPath() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("c", to: "b")

		let layers = try #require(graph.topologicalLayers())

		#expect(layers == [["a"], ["c"], ["b"]])
	}

/// Tests that every edge advances by at least one layer, which is the
/// property the layering exists to provide.
///
	@Test("Every Edge Advances", arguments: LayerAlignment.allCases)
	func everyEdgeAdvances(alignment: LayerAlignment) throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d", "e", "f"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("c", to: "b")
		try graph.connect("b", to: "d")
		try graph.connect("a", to: "d")
		try graph.connect("e", to: "d")
		try graph.connect("d", to: "f")

		let layers = try #require(graph.topologicalLayers(alignment: alignment))

		var assignment: [String: Int] = [:]
		for (index, layer) in layers.enumerated() {
			for node in layer {
				assignment[node] = index
			}
		}

		for edge in graph.edges {
			let source = try #require(graph.source(of: edge))
			let target = try #require(graph.target(of: edge))

			let from = try #require(assignment[source])
			let to = try #require(assignment[target])

			#expect(from < to)
		}
	}

/// Tests that every node appears in exactly one layer.
///
	@Test("Partitions Every Node", arguments: LayerAlignment.allCases)
	func partitionsEveryNode(alignment: LayerAlignment) throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "isolated"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		let layers = try #require(graph.topologicalLayers(alignment: alignment))
		let all = layers.flatMap { $0 }

		#expect(all.count == graph.nodeCount)
		#expect(Set(all) == Set(graph.nodes))
	}

/// Tests that placing a node as late as possible moves it alongside the nodes
/// that consume it.
///
	@Test("Latest Alignment")
	func latestAlignment() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "d")
		try graph.connect("c", to: "d")

		// Placed as early as possible, "c" sits beside "a" even though nothing
		// needs it until "d".
		//
		let earliest = try #require(graph.topologicalLayers(alignment: .earliest))
		#expect(Set(earliest[0]) == ["a", "c"])
		#expect(earliest[1] == ["b"])
		#expect(earliest[2] == ["d"])

		// Placed as late as possible, it moves next to "d".
		//
		let latest = try #require(graph.topologicalLayers(alignment: .latest))
		#expect(latest[0] == ["a"])
		#expect(Set(latest[1]) == ["b", "c"])
		#expect(latest[2] == ["d"])
	}

/// Tests that both alignments produce the same number of layers, as the
/// critical path does not depend on where the slack is taken up.
///
	@Test("Alignment Preserves Depth")
	func alignmentPreservesDepth() throws {
		let graph = try pipeline()

		let earliest = try #require(graph.topologicalLayers(alignment: .earliest))
		let latest = try #require(graph.topologicalLayers(alignment: .latest))

		#expect(earliest.count == latest.count)
	}

/// Tests that the number of layers is the length of the longest chain in the
/// graph.
///
	@Test("Depth Is The Critical Path")
	func depthIsTheCriticalPath() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d", "shortcut"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "d")
		try graph.connect("a", to: "shortcut")
		try graph.connect("shortcut", to: "d")

		let layers = try #require(graph.topologicalLayers())

		// The longest chain is a → b → c → d, which is four nodes.
		//
		#expect(layers.count == 4)
	}

/// Tests that a node connected to nothing is placed first when aligned
/// early, and last when aligned late.
///
	@Test("Isolated Node")
	func isolatedNode() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "isolated"], options: .acyclic)
		try graph.connect("a", to: "b")

		let earliest = try #require(graph.topologicalLayers(alignment: .earliest))
		let latest = try #require(graph.topologicalLayers(alignment: .latest))

		#expect(earliest[0].contains("isolated"))
		#expect(latest[latest.count - 1].contains("isolated"))
	}

/// Tests that the layer of a single node agrees with the layering of the
/// whole graph.
///
	@Test("Layer Of Node", arguments: LayerAlignment.allCases)
	func layerOfNode(alignment: LayerAlignment) throws {
		let graph = try pipeline()
		let layers = try #require(graph.topologicalLayers(alignment: alignment))

		for (index, layer) in layers.enumerated() {
			for node in layer {
				#expect(graph.layer(of: node, alignment: alignment) == index)
			}
		}

		#expect(graph.layer(of: "unknown") == nil)
	}

/// Tests that layering by incoming edges reverses the result.
///
	@Test("Incoming")
	func incoming() throws {
		let graph = try pipeline()

		let outgoing = try #require(graph.topologicalLayers(in: .outgoing))
		let incoming = try #require(graph.topologicalLayers(in: .incoming))

		#expect(incoming.count == outgoing.count)
		#expect(incoming[0] == ["output"])
		#expect(Set(incoming[incoming.count - 1]) == ["texture", "shader"])
	}

/// Tests that a graph containing a cycle cannot be layered.
///
	@Test("Rejects Cycles", arguments: LayerAlignment.allCases)
	func rejectsCycles(alignment: LayerAlignment) throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "b")

		#expect(graph.topologicallySorted() == nil)
		#expect(graph.topologicalLayers(alignment: alignment) == nil)
		#expect(graph.layer(of: "a", alignment: alignment) == nil)
	}

/// Tests that a node connected to itself cannot be layered.
///
	@Test("Rejects Self Loops")
	func rejectsSelfLoops() throws {
		var graph = Graph<String, Void>(nodes: ["a"])
		try graph.connect("a", to: "a")

		#expect(graph.topologicalLayers() == nil)
	}

/// Tests that an empty graph produces no layers, rather than one empty layer.
///
	@Test("Empty")
	func empty() throws {
		let graph = Graph<String, Void>()

		#expect(graph.topologicalLayers() == [])
	}

/// Tests that a graph with no edges places every node in a single layer.
///
	@Test("No Edges")
	func noEdges() throws {
		let graph = Graph<String, Void>(nodes: ["a", "b", "c"])
		let layers = try #require(graph.topologicalLayers())

		#expect(layers.count == 1)
		#expect(Set(layers[0]) == ["a", "b", "c"])
	}

/// Tests that flattening the layers produces a valid topological order.
///
	@Test("Agrees With Topological Sort", arguments: LayerAlignment.allCases)
	func agreesWithTopologicalSort(alignment: LayerAlignment) throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d", "e"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("b", to: "d")
		try graph.connect("c", to: "d")
		try graph.connect("d", to: "e")

		let layers = try #require(graph.topologicalLayers(alignment: alignment))
		let flattened = layers.flatMap { $0 }

		var position: [String: Int] = [:]
		for (index, node) in flattened.enumerated() {
			position[node] = index
		}

		for edge in graph.edges {
			let source = try #require(graph.source(of: edge))
			let target = try #require(graph.target(of: edge))

			#expect(position[source]! < position[target]!)
		}
	}

/// Tests that a deep graph is layered without exhausting the stack.
///
	@Test("Deep Graph")
	func deepGraph() throws {
		let nodes = (0..<5000).map { "\($0)" }
		var graph = Graph<String, Void>(nodes: nodes, options: .acyclic)

		for index in 1..<nodes.count {
			try graph.connect(nodes[index - 1], to: nodes[index])
		}

		let layers = try #require(graph.topologicalLayers())

		#expect(layers.count == nodes.count)
		#expect(layers.allSatisfy { $0.count == 1 })
	}
}
