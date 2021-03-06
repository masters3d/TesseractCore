//  Copyright (c) 2015 Rob Rix. All rights reserved.

public func evaluate(graph: Graph<Node>, from: Identifier, _ environment: Environment = Prelude, _ visited: [Identifier: Memo<Value>] = [:]) -> Either<Error<Identifier>, Memo<Value>> {
	return
		visited[from].map(Either.right)
	??	graph.nodes[from].map { evaluate(graph, from, environment, visited, $0) }
	??	error("could not find identifier in graph", from)
}

private func evaluate(graph: Graph<Node>, from: Identifier, environment: Environment, visited: [Identifier: Memo<Value>], node: Node) -> Either<Error<Identifier>, Memo<Value>> {
	let recur: Edge.Source -> Either<Error<Identifier>, Memo<Value>> = { source in
		evaluate(graph, source.identifier, environment, visited, graph.nodes[source.identifier]!)
	}
	let inputs = lazy(graph.edges)
		.filter { $0.destination.identifier == from }
		.map { ($0.destination.inputIndex, recur($0.source)) }
		|> (flip(sorted) <| { $0.0 < $1.0 })

	switch node {
	case let .Symbolic(symbol):
		return coalesce(inputs) >>- { inputs in
				environment[symbol].map { apply($0, from, symbol, inputs, environment) }
			??	error("\(symbol) not found in environment", from)
		}

	case let .Parameter(symbol):
		return environment[.Parameter(0, .Unit)]
			.map { .right(Memo($0)) }
		??	error("did not find parameter in environment", from)

	case .Return where inputs.count != 1:
		return error("expected one return edge, but \(inputs.count) were found", from)

	case .Return:
		return inputs[0].1
	}
}


// MARK: - Imports

import Either
import Memo
import Prelude
