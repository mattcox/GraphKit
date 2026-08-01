//
//  GraphError.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// An error describing why an operation on a graph could not be performed.
///
/// Every operation that can fail is declared using typed throws, so the error
/// is always statically known to be a `GraphError`.
///
/// An operation that throws never modifies the graph.
///
public enum GraphError: Error {
/// An error indicating that _something_ already exists, usually in cases
/// where it is being added.
///
/// - Parameters:
///   - what: The thing that already exists.
///   - reason: The reason the thing already exists.
///   - file: The file that the error occurred in.
///   - function: The function that the failure occurred in.
///   - line: The line of the file that the failure occurred on.
///
	case alreadyExists(what: String, reason: String? = nil, file: String = #file, function: String = #function, line: Int = #line)

/// An error indicating that _something_ is not permitted by the topology the
/// graph is allowed to represent.
///
/// The thing that is not allowed describes the constraint that rejected the
/// operation, such as a cycle or a self loop. The ``GraphOptions`` describing
/// the graph determine which constraints are enforced.
///
/// - Parameters:
///   - what: The thing that is not allowed.
///   - reason: The reason the thing is not allowed.
///   - file: The file that the error occurred in.
///   - function: The function that the failure occurred in.
///   - line: The line of the file that the failure occurred on.
///
	case notAllowed(what: String, reason: String? = nil, file: String = #file, function: String = #function, line: Int = #line)

/// An error indicating that _something_ cannot be found.
///
/// - Parameters:
///   - what: The thing that cannot be found.
///   - reason: The reason the thing cannot be found.
///   - file: The file that the error occurred in.
///   - function: The function that the failure occurred in.
///   - line: The line of the file that the failure occurred on.
///
	case notFound(what: String, reason: String? = nil, file: String = #file, function: String = #function, line: Int = #line)

/// An error indicating that _something_ is out of bounds.
///
/// - Parameters:
///   - reason: The reason the thing is out of bounds.
///   - file: The file that the error occurred in.
///   - function: The function that the failure occurred in.
///   - line: The line of the file that the failure occurred on.
///
	case outOfBounds(_ reason: String? = nil, file: String = #file, function: String = #function, line: Int = #line)
}

extension GraphError {
/// The thing an error describes, ignoring the reason it occurred and the
/// location it was thrown from.
///
/// This is the part of an error that identifies the failure, and is what two
/// errors are compared by.
///
	private var subject: String {
		switch self {
			case .alreadyExists(let what, _, _, _, _):
				"alreadyExists.\(what)"

			case .notAllowed(let what, _, _, _, _):
				"notAllowed.\(what)"

			case .notFound(let what, _, _, _, _):
				"notFound.\(what)"

			case .outOfBounds:
				"outOfBounds"
		}
	}

/// Returns a string describing the file, function and line an error
/// occurred, parsed from the input arguments.
///
/// In release builds, the function returns an empty string.
///
/// - Parameters:
///   - file: The file that the error occurred in.
///   - function: The function that the failure occurred in.
///   - line: The line of the file that the failure occurred on.
///
/// - Returns: A string describing the location of an error.
///
	@inline(__always)
	private nonmutating func fileFunctionLineString(_ file: String, _ function: String, _ line: Int) -> String {
#if DEBUG
		" - [At line: \(line), in function: \(function)(), in file \"\(file)\"]"
#else
		""
#endif
	}
}

// The things a graph error can describe. These are provided so that an error
// can be matched against without reproducing the string it carries.
//
// An error is most readably matched by comparing it, as two errors are equal
// when they describe the same failure of the same thing.
//
// ```swift
// catch {
//     if error == GraphError.notAllowed(what: GraphError.cycle) {
//         // . . .
//     }
// }
// ```
//
// Comparing inside the catch block is preferred over a `catch ... where`
// clause, which can crash the Swift 6.2 compiler when it appears in top level
// code and does not cover every error.
//
extension GraphError {
/// A node in the graph.
///
	public static var node: String {
		"Node"
	}

/// An edge in the graph, or a handle referring to one.
///
	public static var edge: String {
		"Edge"
	}

/// A walk of the graph that returns to the node it started at.
///
	public static var cycle: String {
		"Cycle"
	}

/// An edge connecting a node to itself.
///
	public static var selfLoop: String {
		"Self Loop"
	}

/// A second edge arriving at a node that already has one.
///
	public static var multipleIncomingEdges: String {
		"Multiple Incoming Edges"
	}
}

extension GraphError: CustomDebugStringConvertible {
/// A textual description of the error, including the reason it occurred.
///
/// In debug builds, the description also reports the file, function and line
/// the error was thrown from.
///
	public var debugDescription: String {
		switch self {
			case .alreadyExists(let what, let reason, let file, let function, let line):
				if let reason = reason {
					"Already Exists (\(what)): \"\(reason)\"\(fileFunctionLineString(file, function, line))."
				}
				else {
					"Already Exists (\(what))\(fileFunctionLineString(file, function, line))."
				}

			case .notAllowed(let what, let reason, let file, let function, let line):
				if let reason = reason {
					"Not Allowed (\(what)): \"\(reason)\"\(fileFunctionLineString(file, function, line))."
				}
				else {
					"Not Allowed (\(what))\(fileFunctionLineString(file, function, line))."
				}

			case .notFound(let what, let reason, let file, let function, let line):
				if let reason = reason {
					"Not Found (\(what)): \"\(reason)\"\(fileFunctionLineString(file, function, line))."
				}
				else {
					"Not Found (\(what))\(fileFunctionLineString(file, function, line))."
				}

			case .outOfBounds(let reason, let file, let function, let line):
				if let reason = reason {
					"Out of Bounds: \"\(reason)\"\(fileFunctionLineString(file, function, line))."
				}
				else {
					"Out of Bounds\(fileFunctionLineString(file, function, line))."
				}
		}
	}
}

extension GraphError: CustomStringConvertible {
/// A textual description of the error, including the reason it occurred.
///
	public var description: String {
		debugDescription
	}
}

extension GraphError: Equatable {
/// Compares two errors, ignoring the reason they occurred and the location
/// they were thrown from.
///
/// Two errors are equal when they describe the same failure of the same
/// thing, so an error can be matched against without reproducing the reason
/// it carries, and without regard for where in the package it was raised.
///
/// - Parameters:
///   - lhs: The first error to compare.
///   - rhs: The second error to compare.
///
/// - Returns: True if both errors describe the same failure.
///
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.subject == rhs.subject
	}
}

extension GraphError: Sendable {

}
