//
//  Errors.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Errors")
struct ErrorTests {
/// Tests that two errors describing the same failure are equal, whatever
/// reason they carry and wherever they were thrown from.
///
	@Test("Equality Ignores Diagnostics")
	func equalityIgnoresDiagnostics() throws {
		let first = GraphError.notFound(what: GraphError.node, reason: "One reason.", file: "A.swift", function: "a()", line: 1)
		let second = GraphError.notFound(what: GraphError.node, reason: "Another reason.", file: "B.swift", function: "b()", line: 2)

		#expect(first == second)
	}

/// Tests that errors describing different things are not equal, even when
/// they share a case.
///
	@Test("Equality Distinguishes Subjects")
	func equalityDistinguishesSubjects() throws {
		#expect(GraphError.notFound(what: GraphError.node) != GraphError.notFound(what: GraphError.edge))
		#expect(GraphError.notAllowed(what: GraphError.cycle) != GraphError.notAllowed(what: GraphError.selfLoop))
		#expect(GraphError.notFound(what: GraphError.edge) != GraphError.alreadyExists(what: GraphError.edge))
	}

/// Tests that the constraint that rejected a connection can be told apart
/// from the others.
///
	@Test("Distinguishes Constraints")
	func distinguishesConstraints() throws {
		var tree = Graph<String, Void>(nodes: ["root", "a", "b"], options: .tree)
		try tree.connect("root", to: "a")
		try tree.connect("root", to: "b")

		var caught: GraphError?
		do {
			try tree.connect("a", to: "b")
		}
		catch {
			caught = error
		}

		#expect(caught == GraphError.notAllowed(what: GraphError.multipleIncomingEdges))
		#expect(caught != GraphError.notAllowed(what: GraphError.cycle))
	}

/// Tests that an error describes both the thing that failed and the reason it
/// failed.
///
	@Test("Description")
	func description() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)
		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		var caught: GraphError?
		do {
			try graph.connect("c", to: "a")
		}
		catch {
			caught = error
		}

		let description = try #require(caught?.description)

		#expect(description.hasPrefix("Not Allowed (Cycle): \"The connection would introduce a cycle"))
	}
}
