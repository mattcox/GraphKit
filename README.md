# 🕸️ GraphKit

<p align="center">
    <img src="https://img.shields.io/badge/Swift-orange.svg" alt="Swift" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/swiftpm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>

Welcome to **GraphKit**, a Swift package for describing ordered directed relationships between identifiers.

**GraphKit** models a graph as a value type with no reference counting, no locking and no asynchrony, so a graph can be copied, snapshotted and handed around freely. Connections between nodes are ordered, can be inserted at an explicit position, and can be walked in either direction.

## Usage

### Nodes

A node is an identifier, not a payload. Any `Hashable` type can be used, and the data the node refers to is expected to live elsewhere — most often keyed by the same identifier.

```swift
var parenting = Graph<UUID, Void>()

parenting.insert(document)
parenting.insert(layer)
```

Each graph models exactly one relationship. To describe several relationships over the same nodes, use several graphs sharing the same identifier type.

```swift
var dependencies = Graph<UUID, Void>(options: .acyclic)
var parenting = Graph<UUID, Void>(options: .tree)
```

Removing a node also disconnects every edge connected to it.

```swift
parenting.remove(layer)
```

### Edges

Nodes are connected using directed edges. Connecting returns an opaque handle, which remains valid until the edge is disconnected.

```swift
let edge = try parenting.connect(document, to: layer)
```

The edges connected to a node are ordered, and the ordering is stable for the lifetime of the graph. New edges are appended by default, but can be inserted at an explicit position.

```swift
try parenting.connect(document, to: background, at: .start)
try parenting.connect(document, to: overlay, at: .index(1))
```

Each node maintains an independent ordering for the edges that leave it and the edges that arrive at it, so an edge occupies an independent position at each of its endpoints. An existing edge can be moved within either ordering.

```swift
try parenting.move(edge, to: .end, in: .outgoing)
```

Connections can be walked in either direction.

```swift
let children = parenting.successors(of: document)
let parent = parenting.predecessors(of: layer).first
```

### Values

Each edge carries a value, which can be used to store a weight, a label, a payload, or nothing at all.

```swift
var distances = Graph<String, Double>()

distances.insert(contentsOf: ["London", "Paris", "Rome"])

try distances.connect("London", to: "Paris", value: 344.0)
try distances.connect("Paris", to: "Rome", value: 1100.0)
```

For a graph carrying no value, use `Void`. The `connect` method omits the value entirely in that case.

### Options

The topology a graph is permitted to represent is declared when it is initialized, and is enforced every time an edge is connected. A connection that would violate an option is rejected, leaving the graph untouched.

```swift
var dependencies = Graph<String, Void>(options: .acyclic)

dependencies.insert(contentsOf: ["mesh", "material", "texture"])

try dependencies.connect("mesh", to: "material")
try dependencies.connect("material", to: "texture")

try dependencies.connect("texture", to: "mesh")
// throws GraphError.notAllowed(what: GraphError.cycle)
```

The individual flags are `allowsCycles`, `allowsParallelEdges`, `allowsSelfLoops` and `allowsMultipleIncomingEdges`, alongside the `default`, `acyclic` and `tree` presets.

A connection can also be validated ahead of being attempted.

```swift
if dependencies.wouldCreateCycle(connecting: "texture", to: "mesh") == false {
    try dependencies.connect("texture", to: "mesh")
}
```

### Changes

A group of mutations can be performed as a single transaction, reporting the changes made to the topology of the graph. If the body throws, the graph is restored to the state it held before the transaction began.

```swift
let (edge, changes) = try parenting.withChanges { parenting in
    parenting.insert(layer)
    return try parenting.connect(document, to: layer)
}

for observer in observers {
    observer.graph(parenting, didChange: changes)
}
```

Changes describe topology only, and are recorded only inside a transaction, so an unobserved mutation costs nothing.

### Algorithms

Nodes can be walked breadth first or depth first, in either direction. The traversal is lazy, and holds the graph it was created from, so it can be abandoned part way through and is unaffected by later mutation.

```swift
let stale = dependencies.traversal(from: mesh).first { needsRebuilding($0) }
```

A graph can be ordered so that each node appears before every node it is connected to.

```swift
guard let order = dependencies.topologicallySorted() else {
    throw BuildError.circularDependency
}

for material in order {
    build(material)
}
```

Where ordering flattens the graph into a line, layering keeps the nodes that are
independent of one another together. Every edge advances by at least one layer,
so nothing in a layer depends on anything else in it.

```swift
for (column, layer) in dependencies.topologicalLayers()!.enumerated() {
    for (row, node) in layer.enumerated() {
        position[node] = Point(x: column * 220, y: row * 90)
    }
}
```

That makes each layer safe to evaluate at once, and makes the number of layers
the length of the longest chain in the graph — the critical path.

```swift
for layer in dependencies.topologicalLayers()! {
    await withTaskGroup { group in
        for node in layer {
            group.addTask { evaluate(node) }
        }
    }
}
```

Nodes are placed as early as their dependencies allow by default. Placing them
as late as possible instead groups each node alongside the nodes that consume
it, which usually reads better in a layout.

```swift
dependencies.topologicalLayers(alignment: .latest)
```

Paths can be found by edge count, or by the total weight of the edges walked.

```swift
let hops = parenting.shortestPath(from: document, to: layer)
let route = distances.weightedShortestPath(from: "London", to: "Rome")

let cities = distances.nodes(along: route!, from: "London")
// "London", "Paris", "Rome"
```

Reachability can be tested directly.

```swift
dependencies.reaches(texture, from: mesh)
dependencies.nodes(reachableFrom: mesh)
```

Cycles can be reported rather than only detected, so a rejected connection can
explain itself.

```swift
do {
    try dependencies.connect(texture, to: mesh)
}
catch {
    if error == GraphError.notAllowed(what: GraphError.cycle) {
        let path = dependencies.cycle(connecting: texture, to: mesh)!
        let nodes = dependencies.nodes(along: path, from: mesh)!
        // "Mesh", "Material", "Texture"  —  connecting Texture to Mesh closes it
    }
}
```

An existing cycle can be found the same way, which describes why a graph could
not be ordered.

```swift
if let cycle = dependencies.findCycle() {
    let origin = dependencies.source(of: cycle[0])!
    let nodes = dependencies.nodes(along: cycle, from: origin)
}
```

Nodes can be grouped into strongly connected components — the general form of a
cycle — and into the independent parts of the graph.

```swift
let tangles = dependencies.stronglyConnectedComponents().filter { $0.count > 1 }

for part in dependencies.connectedComponents() {
    evaluate(part)
}
```

Collapsing the strongly connected components always produces an acyclic graph,
so a graph that `topologicallySorted()` cannot order can still be evaluated in
order.

## Design

A graph stores its nodes and edges in slot maps, addressed by dense integers. Node identifiers are interned once, so the cost of an edge is independent of the size of the identifier type, and walking the graph never needs to hash.

Because a graph is a value type backed by copy on write storage, copying one is a constant time operation. This makes a snapshot cheap enough to take on every edit, which is what allows a transaction to roll back, and what allows an algorithm to run against a stable graph while the original continues to be mutated.

Coordination is deliberately left to the caller. A graph is `Sendable` whenever its node and value types are, so it can be placed inside an actor, an `@Observable` class, or an undo stack, without the package imposing a concurrency model.

The package imports nothing — not even Foundation — and contains no classes, no existentials, no reflection and no asynchrony. Every failable operation uses typed throws, so the error a call can produce is always statically known.

## Installation

GraphKit is distributed using the [Swift Package Manager](https://swift.org/package-manager). To install it within another Swift package, add it as a dependency within your `Package.swift` manifest:

```swift
let package = Package(
    // . . .
    dependencies: [
        .package(url: "https://github.com/mattcox/GraphKit.git", branch: "main")
    ],
    // . . .
)
```

If you’d like to use GraphKit within an iOS, macOS, watchOS, tvOS or visionOS app, then use Xcode’s `File > Add Packages...` menu command to add it to your project.

Import GraphKit wherever you’d like to use it:
```swift
import GraphKit
```
