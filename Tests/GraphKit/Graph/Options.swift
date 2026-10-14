//
//  Options.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Options")
struct OptionTests {
/// Tests that a graph permits every topology by default.
///
	@Test("Default")
	func `default`() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "b")
		try graph.connect("a", to: "a")
		try graph.connect("b", to: "a")

		#expect(graph.edgeCount == 4)
	}

/// Tests that a connection closing a cycle is rejected in an acyclic graph.
///
	@Test("Rejects Cycles")
	func rejectsCycles() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		#expect(throws: GraphError.notAllowed(what: GraphError.cycle)) {
			try graph.connect("c", to: "a")
		}

		// The rejected connection must leave the graph untouched.
		//
		#expect(graph.edgeCount == 2)
		#expect(graph.isAcyclic)
	}

/// Tests that a connection closing a cycle is detected however long the walk
/// back to the source node is.
///
	@Test("Rejects Distant Cycles")
	func rejectsDistantCycles() throws {
		let nodes = (0..<64).map { "\($0)" }
		var graph = Graph<String, Void>(nodes: nodes, options: .acyclic)

		for index in 1..<nodes.count {
			try graph.connect(nodes[index - 1], to: nodes[index])
		}

		#expect(throws: GraphError.notAllowed(what: GraphError.cycle)) {
			try graph.connect(nodes[63], to: nodes[0])
		}

		// A connection that merges two branches is not a cycle.
		//
		try graph.connect(nodes[0], to: nodes[63])
		#expect(graph.isAcyclic)
	}

/// Tests that a self loop is rejected as a cycle, as well as by the option
/// describing self loops.
///
	@Test("Rejects Self Loops")
	func rejectsSelfLoops() throws {
		var acyclic = Graph<String, Void>(nodes: ["a"], options: .acyclic)
		#expect(throws: GraphError.notAllowed(what: GraphError.selfLoop)) {
			try acyclic.connect("a", to: "a")
		}

		var cyclic = Graph<String, Void>(nodes: ["a"], options: [.allowsCycles, .allowsMultipleIncomingEdges])
		#expect(throws: GraphError.notAllowed(what: GraphError.selfLoop)) {
			try cyclic.connect("a", to: "a")
		}

		#expect(acyclic.edgeCount == 0)
		#expect(cyclic.edgeCount == 0)
	}

/// Tests that a second edge between the same ordered pair of nodes is
/// rejected when parallel edges are not permitted.
///
	@Test("Rejects Parallel Edges")
	func rejectsParallelEdges() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"], options: [.allowsCycles, .allowsMultipleIncomingEdges])

		try graph.connect("a", to: "b")

		#expect(throws: GraphError.alreadyExists(what: GraphError.edge)) {
			try graph.connect("a", to: "b")
		}

		// An edge in the opposite direction is not a parallel edge.
		//
		try graph.connect("b", to: "a")
		#expect(graph.edgeCount == 2)
	}

/// Tests that a node in a tree cannot be given a second predecessor.
///
	@Test("Tree Rejects Multiple Predecessors")
	func treeRejectsMultiplePredecessors() throws {
		var graph = Graph<String, Void>(nodes: ["root", "a", "b", "c"], options: .tree)

		try graph.connect("root", to: "a")
		try graph.connect("root", to: "b")
		try graph.connect("a", to: "c")

		#expect(throws: GraphError.notAllowed(what: GraphError.multipleIncomingEdges)) {
			try graph.connect("b", to: "c")
		}

		#expect(graph.edgeCount == 3)
		#expect(graph.predecessors(of: "c") == ["a"])
	}

/// Tests that a diamond is permitted in an acyclic graph, but not in a tree.
///
	@Test("Acyclic Permits Diamonds")
	func acyclicPermitsDiamonds() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("b", to: "d")
		try graph.connect("c", to: "d")

		#expect(graph.edgeCount == 4)
		#expect(graph.isAcyclic)
	}

/// Tests that a connection can be validated ahead of being attempted.
///
	@Test("Would Create Cycle")
	func wouldCreateCycle() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		#expect(graph.wouldCreateCycle(connecting: "c", to: "a"))
		#expect(graph.wouldCreateCycle(connecting: "a", to: "c") == false)
		#expect(graph.wouldCreateCycle(connecting: "a", to: "unknown") == false)
	}

/// Tests that asking whether a connection would be accepted refuses exactly
/// what connecting rejects, for every option.
///
	@Test("Can Connect")
	func canConnect() throws {
		var tree = Graph<String, Void>(nodes: ["root", "a", "b", "c"], options: .tree)
		try tree.connect("root", to: "a")
		try tree.connect("a", to: "b")

		#expect(tree.canConnect("a", to: "a") == false)
		#expect(tree.canConnect("root", to: "a") == false)
		#expect(tree.canConnect("root", to: "b") == false)
		#expect(tree.canConnect("b", to: "root") == false)
		#expect(tree.canConnect("b", to: "c"))
		#expect(tree.canConnect("root", to: "c"))

		var unconstrained = Graph<String, Void>(nodes: ["a", "b"], options: [.allowsCycles, .allowsParallelEdges, .allowsSelfLoops, .allowsMultipleIncomingEdges])
		try unconstrained.connect("a", to: "b")

		#expect(unconstrained.canConnect("a", to: "a"))
		#expect(unconstrained.canConnect("a", to: "b"))
		#expect(unconstrained.canConnect("b", to: "a"))

		// Asking modifies nothing.
		//
		#expect(tree.edgeCount == 2)
		#expect(unconstrained.edgeCount == 1)
	}

/// Tests that a connection involving a node that is not a member of the
/// graph, or an out of range position, is not accepted, as connecting would
/// reject it.
///
	@Test("Can Connect Rejects Unknown Nodes And Positions")
	func canConnectRejectsUnknownNodesAndPositions() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)
		try graph.connect("a", to: "b")

		#expect(graph.canConnect("a", to: "z") == false)
		#expect(graph.canConnect("z", to: "a") == false)

		#expect(graph.canConnect("a", to: "c", at: .index(1)))
		#expect(graph.canConnect("a", to: "c", at: .index(2)) == false)
		#expect(graph.canConnect("a", to: "c", at: .start))
	}
}
