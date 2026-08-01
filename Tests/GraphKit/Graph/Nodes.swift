//
//  Nodes.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Nodes")
struct NodeTests {
/// Tests that a node can be inserted, and is only inserted once.
///
	@Test("Insert")
	func insert() throws {
		var graph = Graph<String, Void>()

		#expect(graph.isEmpty)

		let inserted = graph.insert("a")
		let reinserted = graph.insert("a")

		#expect(inserted)
		#expect(reinserted == false)
		#expect(graph.nodeCount == 1)
		#expect(graph.contains("a"))
		#expect(graph.contains("b") == false)
		#expect(graph.isEmpty == false)
	}

/// Tests that inserting a node that is already a member of the graph leaves
/// its edges untouched.
///
	@Test("Insert Preserves Edges")
	func insertPreservesEdges() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		try graph.connect("a", to: "b")

		#expect(graph.insert("a") == false)
		#expect(graph.edgeCount == 1)
		#expect(graph.successors(of: "a") == ["b"])
	}

/// Tests that removing a node also disconnects every edge connected to it, in
/// both directions.
///
	@Test("Remove Disconnects Edges")
	func removeDisconnectsEdges() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")
		try graph.connect("c", to: "a")

		#expect(graph.edgeCount == 3)

		let removed = graph.remove("b")
		let removedAgain = graph.remove("b")

		#expect(removed)
		#expect(removedAgain == false)

		#expect(graph.nodeCount == 2)
		#expect(graph.edgeCount == 1)
		#expect(graph.outgoingEdges(of: "a").isEmpty)
		#expect(graph.incomingEdges(of: "c").isEmpty)
		#expect(graph.successors(of: "c") == ["a"])
	}

/// Tests that removing a node connected to itself does not leave the edge
/// behind.
///
	@Test("Remove Node With Self Loop")
	func removeNodeWithSelfLoop() throws {
		var graph = Graph<String, Void>(nodes: ["a"])
		try graph.connect("a", to: "a")

		#expect(graph.edgeCount == 1)

		let removed = graph.remove("a")

		#expect(removed)
		#expect(graph.edgeCount == 0)
		#expect(graph.isEmpty)
	}

/// Tests that the slot vacated by a removed node is recycled, and that the
/// recycled slot does not inherit the edges of the node that vacated it.
///
	@Test("Slot Recycling")
	func slotRecycling() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		try graph.connect("a", to: "b")

		graph.remove("b")
		graph.insert("c")

		#expect(graph.nodeCount == 2)
		#expect(graph.edgeCount == 0)
		#expect(graph.outgoingEdges(of: "a").isEmpty)
		#expect(graph.incomingEdges(of: "c").isEmpty)
	}

/// Tests that removing every node and edge empties the graph.
///
	@Test("Remove All")
	func removeAll() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		try graph.connect("a", to: "b")

		graph.removeAll()

		#expect(graph.isEmpty)
		#expect(graph.nodeCount == 0)
		#expect(graph.edgeCount == 0)
	}

/// Tests that a graph is a value type, and that mutating a copy does not
/// affect the original.
///
	@Test("Value Semantics")
	func valueSemantics() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		try graph.connect("a", to: "b")

		let snapshot = graph

		graph.remove("b")
		graph.insert("c")

		#expect(snapshot.nodeCount == 2)
		#expect(snapshot.edgeCount == 1)
		#expect(snapshot.contains("c") == false)
		#expect(graph.edgeCount == 0)
	}
}
