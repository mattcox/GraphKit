//
//  LayerAlignment.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// Where a node is placed when the layers it could occupy leave it a choice.
///
/// A node is constrained to sit after every node it depends upon, and before
/// every node that depends upon it. A node whose constraints do not pin it to a
/// single layer can be placed anywhere between the two, and the alignment
/// decides where.
///
public enum LayerAlignment {
/// Place each node in the earliest layer its dependencies allow.
///
/// Every node sits immediately after the last of the nodes it depends upon,
/// so a node that depends upon nothing is placed in the first layer.
///
	case earliest

/// Place each node in the latest layer its dependents allow.
///
/// Every node sits immediately before the first of the nodes that depend upon
/// it, so a node that nothing depends upon is placed in the last layer.
///
/// This tends to read better when laying a graph out, as it groups each node
/// alongside the nodes that consume it rather than leaving it stranded beside
/// the nodes it was produced with.
///
	case latest
}

extension LayerAlignment: CaseIterable {

}

extension LayerAlignment: Hashable {

}

extension LayerAlignment: Sendable {

}
