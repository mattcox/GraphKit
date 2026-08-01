//
//  GraphOptions.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// A set of flags describing the topology a graph is permitted to represent.
///
/// The options are fixed for the lifetime of a graph, and are enforced every
/// time an edge is connected. An edge that would violate an option is rejected
/// with a ``GraphError``, leaving the graph unmodified.
///
/// ```swift
/// // A dependency graph, where a cycle would be a modelling error.
/// var dependencies = Graph<UUID, Void>(options: .acyclic)
/// ```
///
public struct GraphOptions: OptionSet {
/// The raw value describing the options, where each option occupies a single
/// bit.
///
	public let rawValue: UInt8

/// Initialize the options using a raw value.
///
/// - Parameters:
///   - rawValue: The raw value describing the options.
///
	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
}

extension GraphOptions {
/// The graph may contain directed cycles.
///
/// When this option is absent, every connection is validated by testing
/// whether the target node can already reach the source node. If it can, the
/// connection is rejected with ``GraphError/wouldCreateCycle``.
///
/// The validation walks the graph reachable from the target node, so
/// connecting an edge in an acyclic graph costs `O(V + E)` in the worst case
/// rather than `O(1)`.
///
	public static var allowsCycles: Self {
		Self(rawValue: 1 << 0)
	}

/// The graph may contain more than one edge between the same ordered pair of
/// nodes.
///
/// When this option is absent, connecting two nodes that are already
/// connected in the same direction is rejected with
/// ``GraphError/edgeAlreadyExists``.
///
	public static var allowsParallelEdges: Self {
		Self(rawValue: 1 << 1)
	}

/// The graph may contain edges that connect a node to itself.
///
/// When this option is absent, connecting a node to itself is rejected with
/// ``GraphError/selfLoopNotAllowed``.
///
/// A self loop is a cycle, so it is additionally rejected in a graph that
/// does not contain ``allowsCycles``.
///
	public static var allowsSelfLoops: Self {
		Self(rawValue: 1 << 2)
	}

/// A node in the graph may have more than one edge arriving at it.
///
/// When this option is absent, connecting to a node that already has an edge
/// arriving at it is rejected with
/// ``GraphError/multipleIncomingEdgesNotAllowed``. Every node therefore has
/// at most one predecessor, which is the constraint that separates a tree
/// from a directed acyclic graph.
///
	public static var allowsMultipleIncomingEdges: Self {
		Self(rawValue: 1 << 3)
	}

/// The default options, describing an unconstrained directed multigraph.
///
/// Cycles, parallel edges and self loops are all permitted, and connecting
/// two nodes never requires the graph to be walked.
///
	public static var `default`: Self {
		[.allowsCycles, .allowsParallelEdges, .allowsSelfLoops, .allowsMultipleIncomingEdges]
	}

/// Options describing a directed acyclic graph.
///
/// A node may have any number of edges arriving at it, and parallel edges are
/// permitted, but neither cycles nor self loops are.
///
	public static var acyclic: Self {
		[.allowsParallelEdges, .allowsMultipleIncomingEdges]
	}

/// Options describing a tree.
///
/// Every node has at most one edge arriving at it, and no walk of the graph
/// returns to the node it started at. A graph built with these options is a
/// forest, becoming a tree once a single node remains without a predecessor.
///
	public static var tree: Self {
		[]
	}
}

extension GraphOptions: Hashable {

}

extension GraphOptions: Sendable {

}
