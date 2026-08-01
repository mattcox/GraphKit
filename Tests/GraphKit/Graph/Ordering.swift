//
//  Ordering.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Ordering")
struct OrderingTests {
/// Tests that edges are appended in the order they are connected, by default.
///
	@Test("Default Order")
	func defaultOrder() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"])

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("a", to: "d")

		#expect(graph.successors(of: "a") == ["b", "c", "d"])
	}

/// Tests that an edge can be inserted at an explicit position.
///
	@Test("Insert At Position")
	func insertAtPosition() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"])

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c", at: .start)
		try graph.connect("a", to: "d", at: .index(1))

		#expect(graph.successors(of: "a") == ["c", "d", "b"])
	}

/// Tests that inserting an edge beyond the end of the ordering is rejected,
/// and that inserting at exactly the end is permitted.
///
	@Test("Insert Out Of Bounds")
	func insertOutOfBounds() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b")

		#expect(throws: GraphError.outOfBounds()) {
			try graph.connect("a", to: "c", at: .index(2))
		}

		#expect(throws: GraphError.outOfBounds()) {
			try graph.connect("a", to: "c", at: .index(-1))
		}

		// Inserting at the position one past the end appends.
		//
		try graph.connect("a", to: "c", at: .index(1))
		#expect(graph.successors(of: "a") == ["b", "c"])
	}

/// Tests that each node maintains an independent ordering for each direction.
///
	@Test("Independent Orderings")
	func independentOrderings() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "target"])

		try graph.connect("a", to: "target")
		try graph.connect("b", to: "target", at: .start)

		// The position applies to the ordering of the source node's outgoing
		// edges, so the target node's incoming edges are still in the order
		// they arrived.
		//
		#expect(graph.predecessors(of: "target") == ["a", "b"])
		#expect(graph.outgoingEdges(of: "b").count == 1)
	}

/// Tests that an edge can be moved within an ordering.
///
	@Test("Move")
	func move() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"])

		try graph.connect("a", to: "b")
		let edge = try graph.connect("a", to: "c")
		try graph.connect("a", to: "d")

		try graph.move(edge, to: .start, in: .outgoing)
		#expect(graph.successors(of: "a") == ["c", "b", "d"])

		try graph.move(edge, to: .end, in: .outgoing)
		#expect(graph.successors(of: "a") == ["b", "d", "c"])

		try graph.move(edge, to: .index(1), in: .outgoing)
		#expect(graph.successors(of: "a") == ["b", "c", "d"])
		#expect(graph.index(of: edge, in: .outgoing) == 1)
	}

/// Tests that moving an edge within one direction does not disturb the
/// ordering in the other.
///
	@Test("Move Is Directional")
	func moveIsDirectional() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "target"])

		let first = try graph.connect("a", to: "target")
		let second = try graph.connect("b", to: "target")

		try graph.move(second, to: .start, in: .incoming)

		#expect(graph.predecessors(of: "target") == ["b", "a"])
		#expect(graph.index(of: first, in: .outgoing) == 0)
		#expect(graph.index(of: second, in: .outgoing) == 0)
	}

/// Tests that moving an edge beyond the end of the ordering is rejected.
///
	@Test("Move Out Of Bounds")
	func moveOutOfBounds() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		let edge = try graph.connect("a", to: "b")

		#expect(throws: GraphError.outOfBounds()) {
			try graph.move(edge, to: .index(1), in: .outgoing)
		}
	}

/// Tests that the ordering survives the removal of an unrelated node.
///
	@Test("Order Survives Removal")
	func orderSurvivesRemoval() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c", "d"])

		try graph.connect("a", to: "b")
		try graph.connect("a", to: "c")
		try graph.connect("a", to: "d")

		graph.remove("c")

		#expect(graph.successors(of: "a") == ["b", "d"])
	}
}
