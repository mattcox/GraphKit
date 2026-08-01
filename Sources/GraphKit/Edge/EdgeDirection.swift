//
//  EdgeDirection.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// The direction an edge is walked in, relative to a node.
///
/// Every node maintains a separately ordered collection of edges for each
/// direction, so the direction selects both which edges are visited and which
/// ordering is observed.
///
public enum EdgeDirection {
/// Edges that leave the node, walked towards their target.
///
	case outgoing

/// Edges that arrive at the node, walked towards their source.
///
	case incoming

/// The opposite direction.
///
	public var reversed: Self {
		switch self {
			case .outgoing:
				return .incoming
			case .incoming:
				return .outgoing
		}
	}
}

extension EdgeDirection: CaseIterable {

}

extension EdgeDirection: Hashable {

}

extension EdgeDirection: Sendable {

}
