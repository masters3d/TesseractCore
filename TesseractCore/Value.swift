//  Copyright (c) 2015 Rob Rix. All rights reserved.

public enum Value: Printable {
	public init(constant: Any) {
		self = Constant(Box(constant))
	}

	public init<T, U>(function: T -> U) {
		self = Function(Box(function))
	}

	public init(graph: TesseractCore.Graph<Node>) {
		self = Graph(graph)
	}

	case Constant(Box<Any>)
	case Function(Box<Any>)
	case Graph(TesseractCore.Graph<Node>)

	public func constant<T>() -> T? {
		switch self {
		case let Constant(v):
			return v.value as? T
		default:
			return nil
		}
	}

	public func function<T, U>() -> (T -> U)? {
		switch self {
		case let Function(f):
			return f.value as? T -> U
		default:
			return nil
		}
	}

	public var graph: TesseractCore.Graph<Node>? {
		switch self {
		case let Graph(graph):
			return graph
		default:
			return nil
		}
	}


	public func apply(argument: Value, _ identifier: Identifier, _ environment: Environment) -> Either<Error<Identifier>, Memo<Value>> {
		switch self {
		case let Function(function) where function.value is Any -> Any:
			return argument.constant()
				.map(function.value as Any -> Any)
				.map { applied in .right(Memo(Value(constant: applied))) }
			??	error("could not apply function", identifier)
		case let Graph(graph):
			return graph
				.find { $1.isReturn }
				.map { evaluate(graph, graph[$0].0, environment + (.Parameter(0, .Unit), argument)) }
			??	error("could not find return node", identifier)
		default:
			return error("cannot apply \(self)", identifier)
		}
	}


	// MARK: Printable

	public var description: String {
		switch self {
		case let Constant(constant):
			return ".Constant(\(constant))"
		case let Function(function):
			return ".Function(\(function))"
		case let Graph(graph):
			return ".Graph(\(graph))"
		}
	}
}


// MARK: - Imports

import Box
import Either
import Memo
