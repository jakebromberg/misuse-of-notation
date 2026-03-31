// Distributivity of multiplication over addition: a * (b + c) = a*b + a*c.
//
// The flat encoding makes this natural: a * (b + c) has (b + c) groups of a
// ticks, which is structurally b groups followed by c groups. ProductSeed<Q>
// wraps an existing product proof Q (for a * b), and TimesTick/TimesGroup
// layers on top represent the a * c part. A MultiplicationDistributive protocol tracks
// the sum witness through the induction.

// MARK: - ProductSeed

/// Wraps an existing `NaturalProduct` proof as a base case for proof extension.
/// Analogous to `ProofSeed<P>` for addition associativity, but wraps a product
/// proof instead of a sum proof.
///
/// Building groups of ticks on top of `ProductSeed<Q>` constructs the product
/// `a * c`, while the wrapped `Q` represents `a * b`. The combined structure
/// witnesses `a * (b + c)`.
public enum ProductSeed<Q: NaturalProduct>: NaturalProduct {
    public typealias Left = Q.Left
    public typealias Right = Q.Right
    public typealias Total = Q.Total
}

// MARK: - MultiplicationDistributive protocol

/// Tracks a sum witness through a product proof, enabling distributivity.
///
/// For a product proof witnessing `a * (b + c)` built as TimesTick/TimesGroup
/// layers on top of `ProductSeed<Q>` (where Q witnesses `a * b`):
///   - `ProductSeed<Q>`: `DistributiveSum = PlusZero<Q.Total>` (a*b + 0 = a*b)
///   - `TimesTick<P>`: `DistributiveSum = PlusSucc<P.DistributiveSum>` (adds 1 to the sum)
///   - `TimesGroup<P>`: `DistributiveSum = P.DistributiveSum` (group boundary, sum unchanged)
///
/// At the end, `DistributiveSum` witnesses `a*b + a*c = a*(b+c)`.
public protocol MultiplicationDistributive: NaturalProduct {
    associatedtype DistributiveSum: NaturalSum
}

// Base case: ProductSeed<Q> wraps a proof of a * b = T.
// The sum starts at T + 0 = T (no a*c contribution yet).
extension ProductSeed: MultiplicationDistributive {
    public typealias DistributiveSum = PlusZero<Q.Total>
}

// Inductive step (tick): each TimesTick adds 1 to Total.
// PlusSucc adds 1 to the sum Total, tracking the correspondence.
extension TimesTick: MultiplicationDistributive where Proof: MultiplicationDistributive {
    public typealias DistributiveSum = PlusSucc<Proof.DistributiveSum>
}

// Inductive step (group): TimesGroup doesn't change Total.
// The sum passes through unchanged.
extension TimesGroup: MultiplicationDistributive where Proof: MultiplicationDistributive {
    public typealias DistributiveSum = Proof.DistributiveSum
}

// Degenerate case: TimesZero<N> witnesses N * 0 = 0.
// The sum is 0 + 0 = 0.
extension TimesZero: MultiplicationDistributive {
    public typealias DistributiveSum = PlusZero<Zero>
}
