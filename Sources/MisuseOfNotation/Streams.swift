// Coinductive streams for continued fraction coefficients.
//
// A CFStream is an infinite sequence of natural number coefficients.
// For periodic continued fractions, self-referential types create a
// productive fixed point: PhiCF.Tail = PhiCF makes the type genuinely
// infinite. Swift resolves this lazily -- chaining .Tail.Tail...Head
// always terminates because each .Tail resolves to a concrete type.
//
// The streams encode the *identity* of an irrational number (its CF
// coefficient sequence), not the *computation* of convergents. Universal
// convergent extraction remains bounded-depth via macros because the CF
// recurrence h_{n+1} = a*h_n + h_{n-1} requires adding two abstract
// naturals in one step, which Swift's conditional conformance cannot express.

// MARK: - CFStream protocol

/// A coinductive stream of continued fraction coefficients.
/// Head is the current coefficient; Tail is the rest of the stream.
/// For periodic CFs, Tail can reference Self (productive fixed point).
public protocol CFStream {
    associatedtype Head: Natural
    associatedtype Tail: CFStream
}

// MARK: - Type equality assertion for streams

/// Compile-time type equality assertion for CFStream types. Same semantics
/// as `assertEqual` for Integers: the assertion is the successful compilation.
public func assertStreamEqual<T: CFStream>(_: T.Type, _: T.Type) {}

// MARK: - Concrete periodic streams

/// Golden ratio phi = [1; 1, 1, 1, ...] -- entirely periodic.
/// The simplest continued fraction: every coefficient is 1.
/// Self-referential: PhiCF.Tail = PhiCF (productive fixed point).
public struct PhiCF: CFStream {
    public typealias Head = N1
    public typealias Tail = PhiCF
}

/// Periodic tail of sqrt(2): [2; 2, 2, ...].
/// Self-referential: Sqrt2Periodic.Tail = Sqrt2Periodic.
public struct Sqrt2Periodic: CFStream {
    public typealias Head = N2
    public typealias Tail = Sqrt2Periodic
}

/// sqrt(2) = [1; 2, 2, 2, ...] -- transient first coefficient, then periodic.
/// Head = 1 (the floor of sqrt(2)), Tail = Sqrt2Periodic (the repeating part).
public struct Sqrt2CF: CFStream {
    public typealias Head = N1
    public typealias Tail = Sqrt2Periodic
}

// MARK: - Universal unfold theorem: PhiCF

/// Proves PhiCF unfolds to itself at any depth n.
/// For all n, the n-th Tail of PhiCF is PhiCF.
///
/// Proved by induction on the depth using the Seed-based pattern:
/// PhiUnfoldSeed (base) provides depth 0, and AddOne (step) applies .Tail.
/// Since PhiCF.Tail = PhiCF, Unfolded = PhiCF at every depth.
public protocol PhiUnfold: Natural {
    associatedtype Unfolded: CFStream
}

/// Seed type for PhiUnfold induction (represents depth 0).
public enum PhiUnfoldSeed: Natural {
    public typealias Successor = AddOne<Self>
    public typealias Predecessor = SubOne<Zero>
}

// Base case: at depth 0, the unfolded stream is PhiCF itself.
extension PhiUnfoldSeed: PhiUnfold {
    public typealias Unfolded = PhiCF
}

// Inductive step: at depth n+1, unfold one more Tail.
// Resolves: PhiCF.Tail = PhiCF, so Unfolded = PhiCF at every depth.
extension AddOne: PhiUnfold where Predecessor: PhiUnfold {
    public typealias Unfolded = Predecessor.Unfolded.Tail
}

// MARK: - Universal unfold theorem: Sqrt2Periodic

/// Proves Sqrt2Periodic unfolds to itself at any depth n.
/// For all n, the n-th Tail of Sqrt2Periodic is Sqrt2Periodic.
///
/// Same structure as PhiUnfold. Since Sqrt2Periodic.Tail = Sqrt2Periodic,
/// Unfolded = Sqrt2Periodic at every depth.
public protocol Sqrt2PeriodicUnfold: Natural {
    associatedtype Unfolded: CFStream
}

/// Seed type for Sqrt2PeriodicUnfold induction (represents depth 0).
public enum Sqrt2PeriodicUnfoldSeed: Natural {
    public typealias Successor = AddOne<Self>
    public typealias Predecessor = SubOne<Zero>
}

// Base case: at depth 0, the unfolded stream is Sqrt2Periodic itself.
extension Sqrt2PeriodicUnfoldSeed: Sqrt2PeriodicUnfold {
    public typealias Unfolded = Sqrt2Periodic
}

// Inductive step: at depth n+1, unfold one more Tail.
// Resolves: Sqrt2Periodic.Tail = Sqrt2Periodic, so Unfolded = Sqrt2Periodic at every depth.
extension AddOne: Sqrt2PeriodicUnfold where Predecessor: Sqrt2PeriodicUnfold {
    public typealias Unfolded = Predecessor.Unfolded.Tail
}
