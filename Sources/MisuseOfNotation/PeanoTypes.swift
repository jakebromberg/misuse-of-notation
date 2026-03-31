// MARK: - Protocol hierarchy

public protocol Integer {
    associatedtype Successor: Integer
    associatedtype Predecessor: Integer
}

public protocol Natural: Integer where Successor: Natural {}

public protocol Nonpositive: Integer where Predecessor: Nonpositive {}

// MARK: - Types

public enum SubOne<Successor: Nonpositive>: Nonpositive {
    public typealias Predecessor = SubOne<Self>
}

public enum Zero: Natural, Nonpositive {
    public typealias Successor = AddOne<Zero>
    public typealias Predecessor = SubOne<Zero>
}

public enum AddOne<Predecessor: Natural>: Natural {
    public typealias Successor = AddOne<Self>
}

// MARK: - Type equality assertion

/// Compile-time type equality assertion. Compiles only when both arguments
/// have the same concrete type. The body is intentionally empty -- the
/// assertion is the successful compilation itself.
public func assertEqual<T: Integer>(_: T.Type, _: T.Type) {}
