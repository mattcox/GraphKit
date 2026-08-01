//
//  EdgePosition.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// A position within a node's ordered collection of edges.
///
/// The edges connected to a node are ordered, and the order is preserved for
/// the lifetime of the graph. A position describes where a new edge should be
/// placed, or where an existing edge should be moved to.
///
public enum EdgePosition {
/// Before every other edge.
///
	case start

/// After every other edge.
///
	case end

/// At an explicit offset.
///
/// The offset is valid in the range `0...count`, where `count` is the number
/// of edges already connected to the node in the relevant direction.
/// Inserting at `count` is equivalent to ``end``.
///
/// - Parameters:
///   - index: The offset to place the edge at.
///
	case index(Int)
}

extension EdgePosition {
/// Resolves the position into an offset suitable for inserting into a
/// collection of the given size.
///
/// - Parameters:
///   - count: The number of edges currently in the collection.
///
/// - Returns: An offset in the range `0...count`.
///
	internal func resolved(insertingInto count: Int) throws(GraphError) -> Int {
		switch self {
			case .start:
				return 0

			case .end:
				return count

			case .index(let index):
				guard index >= 0, index <= count else {
					throw GraphError.outOfBounds("The position lies outside of the ordered edges connected to the node.")
				}
				return index
		}
	}

/// Resolves the position into an offset addressing an existing element in a
/// collection of the given size.
///
/// - Parameters:
///   - count: The number of edges currently in the collection.
///
/// - Returns: An offset in the range `0..<count`.
///
	internal func resolved(addressingInto count: Int) throws(GraphError) -> Int {
		guard count > 0 else {
			throw GraphError.outOfBounds("The position lies outside of the ordered edges connected to the node.")
		}

		switch self {
			case .start:
				return 0

			case .end:
				return count - 1

			case .index(let index):
				guard index >= 0, index < count else {
					throw GraphError.outOfBounds("The position lies outside of the ordered edges connected to the node.")
				}
				return index
		}
	}
}

extension EdgePosition: Hashable {

}

extension EdgePosition: Sendable {

}
