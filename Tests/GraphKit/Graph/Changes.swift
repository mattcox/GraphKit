//
//  Changes.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Testing

@testable import GraphKit

@Suite("Changes")
struct ChangeTests {
/// Tests that the changes made by a transaction are reported in the order
/// they occurred.
///
	@Test("Reports Changes In Order")
	func reportsChangesInOrder() throws {
		var graph = Graph<String, Void>()

		let (edge, changes) = try graph.withChanges { graph in
			graph.insert("a")
			graph.insert("b")
			return try graph.connect("a", to: "b")
		}

		#expect(changes == [
			.nodeInserted("a"),
			.nodeInserted("b"),
			.edgeInserted(edge, source: "a", target: "b", index: 0)
		])
	}

/// Tests that a mutation performed outside of a transaction is not recorded.
///
	@Test("Ignores Unobserved Mutations")
	func ignoresUnobservedMutations() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b"])
		try graph.connect("a", to: "b")

		let (_, changes) = graph.withChanges { graph in
			graph.insert("c")
		}

		#expect(changes == [.nodeInserted("c")])
	}

/// Tests that removing a node reports every edge it disconnects, ahead of
/// reporting the removal itself.
///
	@Test("Reports Cascading Disconnections")
	func reportsCascadingDisconnections() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		let incoming = try graph.connect("a", to: "b")
		let outgoing = try graph.connect("b", to: "c")

		let (_, changes) = graph.withChanges { graph in
			graph.remove("b")
		}

		#expect(changes == [
			.edgeRemoved(outgoing, source: "b", target: "c"),
			.edgeRemoved(incoming, source: "a", target: "b"),
			.nodeRemoved("b")
		])
	}

/// Tests that reordering an edge is reported.
///
	@Test("Reports Reordering")
	func reportsReordering() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"])

		try graph.connect("a", to: "b")
		let edge = try graph.connect("a", to: "c")

		let (_, changes) = try graph.withChanges { graph in
			try graph.move(edge, to: .start, in: .outgoing)
		}

		#expect(changes == [.edgeMoved(edge, from: 1, to: 0, direction: .outgoing)])
	}

/// Tests that a transaction that throws restores the graph, and reports no
/// changes.
///
	@Test("Rolls Back On Failure")
	func rollsBackOnFailure() throws {
		var graph = Graph<String, Void>(nodes: ["a", "b", "c"], options: .acyclic)

		try graph.connect("a", to: "b")
		try graph.connect("b", to: "c")

		let snapshot = graph

		#expect(throws: GraphError.notAllowed(what: GraphError.cycle)) {
			try graph.withChanges { graph in
				graph.insert("d")
				try graph.connect("a", to: "d")

				// This closes a cycle, and fails the whole transaction.
				//
				try graph.connect("c", to: "a")
			}
		}

		#expect(graph.nodeCount == snapshot.nodeCount)
		#expect(graph.edgeCount == snapshot.edgeCount)
		#expect(graph.contains("d") == false)
		#expect(graph.isConnected("a", to: "b"))
	}

/// Tests that a transaction that throws does not leave the graph recording
/// changes.
///
	@Test("Failure Restores Recording State")
	func failureRestoresRecordingState() throws {
		var graph = Graph<String, Void>(nodes: ["a"])

		#expect(throws: GraphError.notFound(what: GraphError.node)) {
			try graph.withChanges { graph in
				try graph.connect("a", to: "b")
			}
		}

		graph.insert("c")
		#expect(graph.changeLog == nil)
	}

/// Tests that a nested transaction reports its own changes, and that those
/// changes are also reported by the transaction enclosing it.
///
	@Test("Nesting")
	func nesting() throws {
		var graph = Graph<String, Void>()

		let (inner, outer) = graph.withChanges { graph in
			graph.insert("a")

			let (_, inner) = graph.withChanges { graph in
				graph.insert("b")
			}

			graph.insert("c")

			return inner
		}

		#expect(inner == [.nodeInserted("b")])
		#expect(outer == [
			.nodeInserted("a"),
			.nodeInserted("b"),
			.nodeInserted("c")
		])
	}

/// Tests that a change is not reported when the value carried by an edge is
/// replaced, as the value is not part of the topology.
///
	@Test("Ignores Value Changes")
	func ignoresValueChanges() throws {
		var graph = Graph<String, Int>(nodes: ["a", "b"])
		let edge = try graph.connect("a", to: "b", value: 1)

		let (_, changes) = try graph.withChanges { graph in
			try graph.setValue(2, of: edge)
		}

		#expect(changes.isEmpty)
		#expect(graph.value(of: edge) == 2)
	}
}
