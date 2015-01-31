//  Copyright (c) 2015 Rob Rix. All rights reserved.

public struct Environment: DictionaryLiteralConvertible {
	private let bindings: [Symbol: Value]

	public subscript (key: String) -> (Symbol, Value)? {
		let index = find(bindings) { symbol, _ in symbol.name == key }
		return index.map { self.bindings[$0] }?
	}

	public subscript (key: Symbol) -> Value? {
		return bindings[key]
	}


	// MARK: DictionaryLiteralConvertible

	public init(dictionaryLiteral elements: (Symbol, Value)...) {
		bindings = Dictionary(elements)
	}
}

public let Prelude: Environment = [
	Symbol("unit", .Unit): Value(constant: ()),
	Symbol("true", .Boolean): Value(constant: true),
	Symbol("false", .Boolean): Value(constant: false),
	Symbol("identity", 0 --> 0): Value(function: id),
	Symbol("const", 0 --> 1 --> 0): Value(function: const as Any -> Any -> Any),
]


public typealias Error = (Identifier, String)

public func evaluate(graph: Graph<Node>, from: Identifier, environment: Environment = Prelude) -> Either<Error, Value> {
	return evaluate(graph, from, environment, [:])
}

private func evaluate(graph: Graph<Node>, from: Identifier, environment: Environment, var visited: [Identifier: Value]) -> Either<Error, Value> {
	func error(reason: String) -> Either<Error, Value> {
		return .left((from, reason))
	}

	if let value = visited[from] {
		return .right(value)
	}

	if let node = graph.nodes[from] {
		let inputs = lazy(graph.edges)
			.filter { $0.destination.identifier == from }
			.map { ($0.destination, graph.nodes[$0.source.identifier]!) }
			|> (flip(sorted) <| { $0.0 < $1.0 })

		switch node {
		case let .Abstraction(symbol):
			switch symbol.type {
			case .Unit:
				return .right(Value(constant: ()))

			default:
				break
			}

		case .Parameter:
			break

		case .Return where inputs.count != 1:
			return error("expected one return edge, but \(inputs.count) were found")

		case .Return:
			return evaluate(graph, inputs[0].0.identifier, environment, visited)
		}
	} else {
		return error("node does not exist in graph")
	}
	return error("unimplemented")
}


// MARK: - Imports

import Either
import Prelude
