//  Copyright (c) 2015 Rob Rix. All rights reserved.

public func evaluate(graph: Graph<Node>, from: Identifier, _ environment: Environment = Prelude, _ visited: [Identifier: Memo<Value>] = [:]) -> Either<Error, Memo<Value>> {
	return
		visited[from].map(Either.right)
	??	graph.nodes[from].map { evaluate(graph, from, environment, visited, $0) }
	??	error("could not find identifier in graph", from)
}

private func evaluate(graph: Graph<Node>, from: Identifier, environment: Environment, visited: [Identifier: Memo<Value>], node: Node) -> Either<Error, Memo<Value>> {
	let recur: Edge.Source -> Either<Error, Memo<Value>> = { source in
		evaluate(graph, source.identifier, environment, visited, graph.nodes[source.identifier]!)
	}
	let inputs = lazy(graph.edges)
		.filter { $0.destination.identifier == from }
		.map { ($0.destination, recur($0.source)) }
		|> (flip(sorted) <| { $0.0 < $1.0 })

	switch node {
	case let .Symbolic(symbol):
		return
			reduce(inputs, Either<Error, [(Edge.Destination, Memo<Value>)]>.right([])) { into, each in
				into >>- { results in (each.1.map { results + [ (each.0, $0) ] }) }
			} >>- { inputs in
					environment[symbol].map(flip(apply) <| inputs <| symbol)
				??	error("\(symbol) not found in environment", from)
			}

	case .Parameter:
		break

	case .Return where inputs.count != 1:
		return error("expected one return edge, but \(inputs.count) were found", from)

	case .Return:
		return inputs[0].1
	}
	return error("don’t know how to evaluate \(node)", from)
}


// MARK: - Imports

import Either
import Memo
import Prelude
