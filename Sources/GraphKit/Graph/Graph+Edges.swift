//
//  Graph+Edges.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

extension Graph {
/// The edges in the graph, in no particular order.
///
/// To enumerate the edges connected to a specific node in their defined
/// order, use ``edges(of:in:)``.
///
	public var edges: some Collection<Edge> {
		let records = edgeRecords
		let generations = edgeGenerations

		return records.indices.lazy.filter {
			records[$0] != nil
		}
		.map {
			Edge(slot: $0, generation: generations[$0])
		}
	}

/// The number of edges in the graph.
///
	public var edgeCount: Int {
		edgeRecords.count - vacantEdgeSlots.count
	}

/// Tests whether the provided edge is a member of the graph.
///
/// - Parameters:
///   - edge: The edge to test for.
///
/// - Returns: True if the edge is a member of the graph.
///
	public func contains(_ edge: Edge) -> Bool {
		record(for: edge) != nil
	}

/// The node an edge leaves.
///
/// - Parameters:
///   - edge: The edge to describe.
///
/// - Returns: The node the edge leaves, or nil if the edge is not a member of
///   the graph.
///
	public func source(of edge: Edge) -> Node? {
		guard let record = record(for: edge) else {
			return nil
		}

		return node(inSlot: record.source)
	}

/// The node an edge arrives at.
///
/// - Parameters:
///   - edge: The edge to describe.
///
/// - Returns: The node the edge arrives at, or nil if the edge is not a
///   member of the graph.
///
	public func target(of edge: Edge) -> Node? {
		guard let record = record(for: edge) else {
			return nil
		}

		return node(inSlot: record.target)
	}

/// The nodes at either end of an edge.
///
/// - Parameters:
///   - edge: The edge to describe.
///
/// - Returns: The nodes the edge connects, or nil if the edge is not a member
///   of the graph.
///
	public func endpoints(of edge: Edge) -> (source: Node, target: Node)? {
		guard let record = record(for: edge) else {
			return nil
		}

		return (node(inSlot: record.source), node(inSlot: record.target))
	}

/// The node at the far end of an edge, when walking from a known endpoint.
///
/// - Parameters:
///   - edge: The edge to walk.
///   - direction: The direction to walk the edge in. Walking an outgoing edge
///   arrives at its target, and walking an incoming edge arrives at its
///   source.
///
/// - Returns: The node at the far end of the edge, or nil if the edge is not
///   a member of the graph.
///
	public func node(traversing edge: Edge, in direction: EdgeDirection) -> Node? {
		guard let record = record(for: edge) else {
			return nil
		}

		switch direction {
			case .outgoing:
				return node(inSlot: record.target)
			case .incoming:
				return node(inSlot: record.source)
		}
	}

/// The value carried by an edge.
///
/// - Parameters:
///   - edge: The edge to read the value of.
///
/// - Returns: The value carried by the edge, or nil if the edge is not a
///   member of the graph.
///
	public func value(of edge: Edge) -> Value? {
		record(for: edge)?.value
	}

/// Replaces the value carried by an edge.
///
/// The value carried by an edge is not part of the topology of the graph, so
/// replacing it is not reported as a change.
///
/// - Parameters:
///   - value: The value to store on the edge.
///   - edge: The edge to store the value on.
///
	public mutating func setValue(_ value: Value, of edge: Edge) throws(GraphError) {
		guard record(for: edge) != nil else {
			throw GraphError.notFound(what: GraphError.edge, reason: "The edge is not a member of the graph.")
		}

		edgeRecords[edge.slot]!.value = value
	}
}

extension Graph {
/// The ordered edges connected to a node in the provided direction.
///
/// The ordering is defined by the graph, and is stable until the edges are
/// explicitly reordered using ``move(_:to:in:)``. Each node maintains an
/// independent ordering for each direction.
///
/// - Parameters:
///   - node: The node to enumerate the edges of.
///   - direction: The direction the edges are connected in.
///
/// - Returns: The ordered edges connected to the node, or an empty collection
///   if the node is not a member of the graph.
///
	public func edges(of node: Node, in direction: EdgeDirection) -> [Edge] {
		guard let slot = nodeSlots[node] else {
			return []
		}

		return edges(inSlot: slot, in: direction)
	}

/// The ordered edges that leave a node.
///
/// - Parameters:
///   - node: The node to enumerate the edges of.
///
/// - Returns: The ordered edges that leave the node.
///
	public func outgoingEdges(of node: Node) -> [Edge] {
		edges(of: node, in: .outgoing)
	}

/// The ordered edges that arrive at a node.
///
/// - Parameters:
///   - node: The node to enumerate the edges of.
///
/// - Returns: The ordered edges that arrive at the node.
///
	public func incomingEdges(of node: Node) -> [Edge] {
		edges(of: node, in: .incoming)
	}

/// The ordered nodes connected to a node in the provided direction.
///
/// A node connected by more than one parallel edge appears once for each
/// edge, at the position of that edge.
///
/// - Parameters:
///   - node: The node to enumerate the neighbors of.
///   - direction: The direction the neighbors are connected in.
///
/// - Returns: The ordered nodes connected to the node.
///
	public func neighbors(of node: Node, in direction: EdgeDirection) -> [Node] {
		edges(of: node, in: direction).map {
			self.node(inSlot: slot(traversing: $0, in: direction))
		}
	}

/// The ordered nodes that the edges leaving a node arrive at.
///
/// - Parameters:
///   - node: The node to enumerate the successors of.
///
/// - Returns: The ordered nodes that the edges leaving the node arrive at.
///
	public func successors(of node: Node) -> [Node] {
		neighbors(of: node, in: .outgoing)
	}

/// The ordered nodes that the edges arriving at a node leave.
///
/// - Parameters:
///   - node: The node to enumerate the predecessors of.
///
/// - Returns: The ordered nodes that the edges arriving at the node leave.
///
	public func predecessors(of node: Node) -> [Node] {
		neighbors(of: node, in: .incoming)
	}

/// The number of edges connected to a node in the provided direction.
///
/// - Parameters:
///   - node: The node to measure.
///   - direction: The direction the edges are connected in.
///
/// - Returns: The number of edges connected to the node, or zero if the node
///   is not a member of the graph.
///
	public func degree(of node: Node, in direction: EdgeDirection) -> Int {
		edges(of: node, in: direction).count
	}

/// The position of an edge within the ordered edges connected to one of its
/// endpoints.
///
/// - Parameters:
///   - edge: The edge to locate.
///   - direction: The direction to locate the edge in. An outgoing edge is
///   located within the node it leaves, and an incoming edge within the node
///   it arrives at.
///
/// - Returns: The position of the edge, or nil if the edge is not a member of
///   the graph.
///
	public func index(of edge: Edge, in direction: EdgeDirection) -> Int? {
		guard let record = record(for: edge) else {
			return nil
		}

		let slot = direction == .outgoing ? record.source : record.target
		return edges(inSlot: slot, in: direction).firstIndex(of: edge)
	}

/// The ordered edges connecting one node to another.
///
/// - Parameters:
///   - source: The node the edges leave.
///   - target: The node the edges arrive at.
///
/// - Returns: The ordered edges connecting the nodes. This contains more than
///   one edge only in a graph containing
///   ``GraphOptions/allowsParallelEdges``.
///
	public func edges(from source: Node, to target: Node) -> [Edge] {
		guard let sourceSlot = nodeSlots[source], let targetSlot = nodeSlots[target] else {
			return []
		}

		return nodeRecords[sourceSlot]!.outgoing.filter {
			edgeRecords[$0.slot]!.target == targetSlot
		}
	}

/// The first edge connecting one node to another.
///
/// - Parameters:
///   - source: The node the edge leaves.
///   - target: The node the edge arrives at.
///
/// - Returns: The first edge connecting the nodes, or nil if they are not
///   connected.
///
	public func edge(from source: Node, to target: Node) -> Edge? {
		guard let sourceSlot = nodeSlots[source], let targetSlot = nodeSlots[target] else {
			return nil
		}

		return nodeRecords[sourceSlot]!.outgoing.first {
			edgeRecords[$0.slot]!.target == targetSlot
		}
	}

/// Tests whether one node is connected directly to another.
///
/// This only tests for a direct connection. To test whether one node can
/// reach another by walking the graph, use ``reaches(_:from:)``.
///
/// - Parameters:
///   - source: The node the edge leaves.
///   - target: The node the edge arrives at.
///
/// - Returns: True if an edge connects the source node to the target node.
///
	public func isConnected(_ source: Node, to target: Node) -> Bool {
		edge(from: source, to: target) != nil
	}
}

extension Graph {
/// Connects one node to another, inserting an edge at the provided position.
///
/// The edge is inserted into the source node's ordered outgoing edges at the
/// provided position, and appended to the target node's ordered incoming
/// edges.
///
/// The connection is validated against the ``options`` describing the graph
/// before anything is modified, so a connection that throws leaves the graph
/// untouched.
///
/// ```swift
/// let edge = try graph.connect(document, to: layer, value: (), at: .start)
/// ```
///
/// - Parameters:
///   - source: The node the edge leaves. This must be a member of the graph.
///   - target: The node the edge arrives at. This must be a member of the
///   graph.
///   - value: The value to store on the edge.
///   - position: The position to insert the edge at within the source node's
///   ordered outgoing edges. Defaults to ``EdgePosition/end``.
///
/// - Returns: A handle referring to the newly connected edge.
///
	@discardableResult
	public mutating func connect(_ source: Node, to target: Node, value: Value, at position: EdgePosition = .end) throws(GraphError) -> Edge {
		let (sourceSlot, targetSlot, index) = try validateConnection(source, to: target, at: position)

		let edge = allocateEdge(source: sourceSlot, target: targetSlot, value: value)
		nodeRecords[sourceSlot]!.outgoing.insert(edge, at: index)
		nodeRecords[targetSlot]!.incoming.append(edge)

		appendChange(.edgeInserted(edge, source: source, target: target, index: index))

		return edge
	}

/// Whether connecting one node to another would be accepted.
///
/// Asks exactly the questions ``connect(_:to:value:at:)`` asks before it
/// modifies anything, so a `true` here means that connect will not throw.
/// Use it to refuse a connection up front, such as a drop destination
/// declining a drag, rather than attempting it and handling the error.
///
/// Like ``connect(_:to:value:at:)``, both nodes must already be members of
/// the graph. A connection involving a node that is not a member is not
/// accepted.
///
/// - Parameters:
///   - source: The node the edge would leave.
///   - target: The node the edge would arrive at.
///   - position: The position the edge would be inserted at within the source
///   node's ordered outgoing edges. Defaults to ``EdgePosition/end``.
///
/// - Returns: True if connecting the source node to the target node at the
/// provided position would succeed.
///
	public func canConnect(_ source: Node, to target: Node, at position: EdgePosition = .end) -> Bool {
		(try? validateConnection(source, to: target, at: position)) != nil
	}

/// Validates a connection against the membership of its nodes, the
/// ``options`` describing the graph, and the position it would be inserted
/// at, without modifying anything.
///
/// The single source of truth for what ``connect(_:to:value:at:)`` accepts,
/// shared with ``canConnect(_:to:at:)`` so the two can never disagree.
///
/// - Returns: The slots of the source and target nodes, and the index the
/// edge would be inserted at within the source node's outgoing edges.
///
	private func validateConnection(_ source: Node, to target: Node, at position: EdgePosition) throws(GraphError) -> (source: Int, target: Int, index: Int) {
		guard let sourceSlot = nodeSlots[source] else {
			throw GraphError.notFound(what: GraphError.node, reason: "The node is not a member of the graph.")
		}

		guard let targetSlot = nodeSlots[target] else {
			throw GraphError.notFound(what: GraphError.node, reason: "The node is not a member of the graph.")
		}

		if sourceSlot == targetSlot, options.contains(.allowsSelfLoops) == false {
			throw GraphError.notAllowed(what: GraphError.selfLoop, reason: "The graph does not allow a node to be connected to itself.")
		}

		if options.contains(.allowsParallelEdges) == false {
			for edge in nodeRecords[sourceSlot]!.outgoing where edgeRecords[edge.slot]!.target == targetSlot {
				throw GraphError.alreadyExists(what: GraphError.edge, reason: "The nodes are already connected, and the graph does not allow parallel edges.")
			}
		}

		if options.contains(.allowsMultipleIncomingEdges) == false {
			if nodeRecords[targetSlot]!.incoming.isEmpty == false {
				throw GraphError.notAllowed(what: GraphError.multipleIncomingEdges, reason: "The node already has an edge arriving at it, and the graph does not allow more than one.")
			}
		}

		// An edge closes a cycle if the node it arrives at can already reach
		// the node it leaves. A self loop is the degenerate case, and is
		// caught by the reachability test treating a node as reaching itself.
		//
		if options.contains(.allowsCycles) == false {
			if slot(targetSlot, reaches: sourceSlot) {
				throw GraphError.notAllowed(what: GraphError.cycle, reason: "The connection would introduce a cycle, and the graph does not allow cycles.")
			}
		}

		// Resolved here, before the caller allocates, so that an invalid
		// position does not leave a vacated slot behind.
		//
		let index = try position.resolved(insertingInto: nodeRecords[sourceSlot]!.outgoing.count)

		return (sourceSlot, targetSlot, index)
	}

/// Disconnects an edge, removing it from both of the nodes it connects.
///
/// - Parameters:
///   - edge: The edge to disconnect.
///
	public mutating func disconnect(_ edge: Edge) throws(GraphError) {
		guard let record = record(for: edge) else {
			throw GraphError.notFound(what: GraphError.edge, reason: "The edge is not a member of the graph.")
		}

		let source = node(inSlot: record.source)
		let target = node(inSlot: record.target)

		nodeRecords[record.source]!.outgoing.removeAll {
			$0 == edge
		}

		nodeRecords[record.target]!.incoming.removeAll {
			$0 == edge
		}

		deallocateEdge(edge)
		appendChange(.edgeRemoved(edge, source: source, target: target))
	}

/// Disconnects every edge connecting one node to another.
///
/// This removes more than one edge only in a graph containing
/// ``GraphOptions/allowsParallelEdges``. Edges connecting the target node
/// back to the source node are not affected.
///
/// - Parameters:
///   - source: The node the edges leave.
///   - target: The node the edges arrive at.
///
/// - Returns: The number of edges that were disconnected.
///
	@discardableResult
	public mutating func disconnect(_ source: Node, from target: Node) -> Int {
		let edges = edges(from: source, to: target)

		for edge in edges {
			try? disconnect(edge)
		}

		return edges.count
	}

/// Moves an edge to a different position within the ordered edges connected
/// to one of its endpoints.
///
/// The position is interpreted against the ordering as it will be once the
/// move has completed, so moving an edge to ``EdgePosition/index(_:)`` places
/// it at exactly that offset.
///
/// - Parameters:
///   - edge: The edge to move.
///   - position: The position to move the edge to.
///   - direction: The ordering to move the edge within. An outgoing edge is
///   moved within the node it leaves, and an incoming edge within the node it
///   arrives at.
///
	public mutating func move(_ edge: Edge, to position: EdgePosition, in direction: EdgeDirection) throws(GraphError) {
		guard let record = record(for: edge) else {
			throw GraphError.notFound(what: GraphError.edge, reason: "The edge is not a member of the graph.")
		}

		let slot = direction == .outgoing ? record.source : record.target

		var ordered = edges(inSlot: slot, in: direction)
		guard let origin = ordered.firstIndex(of: edge) else {
			throw GraphError.notFound(what: GraphError.edge, reason: "The edge is not a member of the graph.")
		}

		let destination = try position.resolved(addressingInto: ordered.count)
		guard destination != origin else {
			return
		}

		ordered.remove(at: origin)
		ordered.insert(edge, at: destination)

		switch direction {
			case .outgoing:
				nodeRecords[slot]!.outgoing = ordered
			case .incoming:
				nodeRecords[slot]!.incoming = ordered
		}

		appendChange(.edgeMoved(edge, from: origin, to: destination, direction: direction))
	}
}

extension Graph where Value == Void {
/// Connects one node to another, inserting an edge at the provided position.
///
/// - Parameters:
///   - source: The node the edge leaves. This must be a member of the graph.
///   - target: The node the edge arrives at. This must be a member of the
///   graph.
///   - position: The position to insert the edge at within the source node's
///   ordered outgoing edges. Defaults to ``EdgePosition/end``.
///
/// - Returns: A handle referring to the newly connected edge.
///
	@discardableResult
	public mutating func connect(_ source: Node, to target: Node, at position: EdgePosition = .end) throws(GraphError) -> Edge {
		try connect(source, to: target, value: (), at: position)
	}
}
