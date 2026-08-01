//
//  TraversalOrder.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// The order the nodes of a graph are visited in when it is walked.
///
/// Both orders visit each reachable node exactly once, and both respect the
/// ordering of the edges connected to each node.
///
public enum TraversalOrder {
/// Visit every node at a given distance from the starting node, before
/// visiting any node that is further away.
///
	case breadthFirst

/// Visit each branch leaving a node in full, before visiting the next branch.
///
	case depthFirst
}

extension TraversalOrder: CaseIterable {

}

extension TraversalOrder: Hashable {

}

extension TraversalOrder: Sendable {

}
