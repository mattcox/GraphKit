//
//  Edges.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Edges")
struct EdgeTests {
/// Tests that connecting two nodes describes the connection from both ends.
///
	@Test("Connect")
	func connect() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		let edge = try graph.connect("a", to: "b")

		#expect(graph.edgeCount == 1)
		#expect(graph.contains(edge))
		#expect(graph.source(of: edge) == "a")
		#expect(graph.target(of: edge) == "b")
		#expect(graph.outgoingEdges(of: "a") == [edge])
		#expect(graph.incomingEdges(of: "b") == [edge])
		#expect(graph.isConnected("a", to: "b"))
		#expect(graph.isConnected("b", to: "a") == false)
	}

/// Tests that connecting a node that is not a member of the graph is
/// rejected, and leaves the graph untouched.
///
	@Test("Connect Unknown Node")
	func connectUnknownNode() throws {
		var graph = Graph<String, Void>(nodes: ["a"])

		#expect(throws: GraphError.notFound(what: GraphError.node)) {
			try graph.connect("a", to: "b")
		}

		#expect(throws: GraphError.notFound(what: GraphError.node)) {
			try graph.connect("b", to: "a")
		}

		#expect(graph.edgeCount == 0)
	}

/// Tests that an edge can be walked in either direction.
///
	@Test("Walk Both Directions")
	func walkBothDirections() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		let edge = try graph.connect("a", to: "b")

		#expect(graph.node(traversing: edge, in: .outgoing) == "b")
		#expect(graph.node(traversing: edge, in: .incoming) == "a")
		#expect(graph.successors(of: "a") == ["b"])
		#expect(graph.predecessors(of: "b") == ["a"])
	}

/// Tests that a value can be stored on an edge, and replaced afterwards.
///
	@Test("Value")
	func value() throws {
		var graph = Graph<String, Int>(nodes: ["a", "b"])
		let edge = try graph.connect("a", to: "b", value: 7)

		#expect(graph.value(of: edge) == 7)

		try graph.setValue(11, of: edge)
		#expect(graph.value(of: edge) == 11)
	}

/// Tests that disconnecting an edge removes it from both of the nodes it
/// connected.
///
	@Test("Disconnect")
	func disconnect() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		let edge = try graph.connect("a", to: "b")

		try graph.disconnect(edge)

		#expect(graph.edgeCount == 0)
		#expect(graph.contains(edge) == false)
		#expect(graph.outgoingEdges(of: "a").isEmpty)
		#expect(graph.incomingEdges(of: "b").isEmpty)

		#expect(throws: GraphError.notFound(what: GraphError.edge)) {
			try graph.disconnect(edge)
		}
	}

/// Tests that disconnecting by node pair removes every parallel edge in that
/// direction, and none in the other.
///
	@Test("Disconnect Node Pair")
	func disconnectNodePair() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "b")
		try graph.connect("b", to: "a")

		#expect(graph.disconnect("a", from: "b") == 2)
		#expect(graph.edgeCount == 1)
		#expect(graph.isConnected("b", to: "a"))
	}

/// Tests that a handle referring to a disconnected edge is rejected, even
/// once its slot has been recycled by a different edge.
///
	@Test("Stale Handle")
	func staleHandle() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		let stale = try graph.connect("a", to: "b")
		try graph.disconnect(stale)

		let fresh = try graph.connect("a", to: "c")

		#expect(stale.slot == fresh.slot)
		#expect(stale != fresh)
		#expect(graph.contains(stale) == false)
		#expect(graph.source(of: stale) == nil)
		#expect(graph.value(of: stale) == nil)

		#expect(throws: GraphError.notFound(what: GraphError.edge)) {
			try graph.disconnect(stale)
		}
	}

/// Tests that a handle survives every mutation other than the removal of the
/// edge it refers to.
///
	@Test("Handle Stability")
	func handleStability() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		let edge = try graph.connect("a", to: "b")

		graph.insert("c")
		try graph.connect("b", to: "c")
		try graph.connect("a", to: "c")
		graph.remove("c")

		#expect(graph.contains(edge))
		#expect(graph.source(of: edge) == "a")
		#expect(graph.target(of: edge) == "b")
	}
}
