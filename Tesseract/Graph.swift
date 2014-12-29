//  Copyright (c) 2014 Rob Rix. All rights reserved.

public struct Identifier: Hashable {
	// MARK: Hashable

	public var hashValue: Int {
		return value.hashValue
	}


	// MARK: Private

	private let value: String
}

public func == (left: Identifier, right: Identifier) -> Bool {
	return left.value == right.value
}


public struct Edge {
	let input: Identifier
	let output: Identifier
}

public struct Graph {
	public init(title: String, nodes: [Identifier] = [], edges: [Edge] = []) {
		self.title = title
		self.nodes = nodes
		self.edges = edges
	}

	public let title: String

	public let nodes: [Identifier]
	public let edges: [Edge]
}
