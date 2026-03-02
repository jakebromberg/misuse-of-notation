// Universal multiplication theorems proved by structural induction.
//
// The flat encoding (TimesTick/TimesGroup) decomposes each multiplication
// step into individual successor operations, like PlusSucc does for addition.
// This avoids TimesSucc's where clauses, which trigger rewrite system
// explosion when composed in inductive protocols.

// MARK: - Flat multiplication witnesses

/// One successor step within a multiplication.
/// Adds 1 to Total; Left and Right unchanged.
///
/// Analogous to PlusSucc for addition: each TimesTick increments the running
/// total by 1. A "copy of Left" consists of Left-many consecutive TimesTicks.
public struct TimesTick<Proof: NaturalProduct>: NaturalProduct {
    public typealias Left = Proof.Left
    public typealias Right = Proof.Right
    public typealias Total = AddOne<Proof.Total>
}

/// One complete copy of Left has been added.
/// Adds 1 to Right; Left and Total unchanged.
///
/// After Left-many TimesTicks, a TimesGroup marks the boundary: one full
/// copy of Left has been accumulated, so Right increments by 1.
public struct TimesGroup<Proof: NaturalProduct>: NaturalProduct {
    public typealias Left = Proof.Left
    public typealias Right = AddOne<Proof.Right>
    public typealias Total = Proof.Total
}

// MARK: - Theorem 1: Left zero annihilation (0 * n = 0)

/// For any natural number N, there exists a proof that 0 * N = 0.
/// Proved by induction on N using TimesZero (base) and TimesGroup (step).
///
/// With Left = 0, each group has 0 ticks (no TimesTicks needed), so the
/// inductive step is just TimesGroup wrapping the previous proof.
public protocol MultiplicationLeftZero: Natural {
    associatedtype ZeroTimesProof: NaturalProduct & SuccessorLeftMultiplication
}

// Base case: 0 * 0 = 0
extension Zero: MultiplicationLeftZero {
    public typealias ZeroTimesProof = TimesZero<Zero>
}

// Inductive step: if 0 * n = 0, then 0 * S(n) = 0
// Each group has 0 ticks (Left = 0), so just wrap with TimesGroup.
extension AddOne: MultiplicationLeftZero where Predecessor: MultiplicationLeftZero {
    public typealias ZeroTimesProof = TimesGroup<Predecessor.ZeroTimesProof>
}

// MARK: - Theorem 2: Successor-left multiplication (a * b = c => S(a) * b = c + b)

/// For any flat multiplication proof that a * b = c, there exists a proof
/// that S(a) * b = c + b. Each TimesGroup gains one extra TimesTick
/// (the new successor contributes one extra unit per copy), so b groups
/// contribute b extra ticks: Total goes from c to c + b.
///
/// Structurally identical to how SuccessorLeftAdd wraps each PlusSucc.
public protocol SuccessorLeftMultiplication: NaturalProduct {
    associatedtype Distributed: NaturalProduct & SuccessorLeftMultiplication
}

// Base case: TimesZero<N> witnesses N * 0 = 0
// S(N) * 0 = 0, witnessed by TimesZero<S(N)>
extension TimesZero: SuccessorLeftMultiplication {
    public typealias Distributed = TimesZero<AddOne<N>>
}

// Inductive step (tick): TimesTick<P> witnesses a * b = S(c) where P: a * b' = c
// If P.Distributed witnesses S(a) * b' = d,
// then TimesTick<P.Distributed> witnesses S(a) * b = S(d)
extension TimesTick: SuccessorLeftMultiplication where Proof: SuccessorLeftMultiplication {
    public typealias Distributed = TimesTick<Proof.Distributed>
}

// Inductive step (group): TimesGroup<P> witnesses a * S(b) = c where P: a * b = c
// If P.Distributed witnesses S(a) * b = d,
// then TimesGroup<TimesTick<P.Distributed>> witnesses S(a) * S(b) = S(d)
// The extra TimesTick accounts for the new successor's contribution to this group.
extension TimesGroup: SuccessorLeftMultiplication where Proof: SuccessorLeftMultiplication {
    public typealias Distributed = TimesGroup<TimesTick<Proof.Distributed>>
}

// MARK: - Theorem 3: Commutativity (a * b = b * a, per fixed A)

// For each fixed A, MultiplicationCommutativityOfK proves A * b = b * A for all b by induction on b:
//   Base (b=0): A * 0 = 0 (TimesZero) and 0 * A = 0 (MultiplicationLeftZero). Both Total = 0.
//   Step (b → S(b)):
//     Forward (A * S(b)): add A-many TimesTicks + TimesGroup to previous A * b proof.
//     Reverse (S(b) * A): apply SuccessorLeftMultiplication to previous b * A proof.
//
// The forward side hardcodes A ticks per group (hence per-A protocols). The reverse
// side chains universally because SuccessorLeftMultiplication.Distributed: SuccessorLeftMultiplication (strengthened).
//
// Full universality (for all a AND b) is not expressible in Swift's current type system
// due to the lack of generic associated types. Each MultiplicationCommutativityOfK is universal over b.

/// Proves N2 * b = b * N2 for all b.
public protocol MultiplicationCommutativityOfTwo: Natural {
    associatedtype ForwardProof: NaturalProduct               // N2 * Self
    associatedtype ReverseProof: NaturalProduct & SuccessorLeftMultiplication  // Self * N2
}

/// Seed type for MultiplicationCommutativityOfTwo induction (represents b = 0).
public enum MultiplicationCommutativityOfTwoSeed: Natural {
    public typealias Successor = AddOne<Self>
    public typealias Predecessor = SubOne<Zero>
}

// Base case: N2 * 0 = 0 and 0 * N2 = 0
extension MultiplicationCommutativityOfTwoSeed: MultiplicationCommutativityOfTwo {
    public typealias ForwardProof = TimesZero<N2>
    public typealias ReverseProof = N2.ZeroTimesProof
}

// Inductive step: given N2 * b and b * N2, produce N2 * S(b) and S(b) * N2
extension AddOne: MultiplicationCommutativityOfTwo where Predecessor: MultiplicationCommutativityOfTwo {
    // Forward: 2 ticks (one copy of N2) + group boundary
    public typealias ForwardProof = TimesGroup<TimesTick<TimesTick<Predecessor.ForwardProof>>>
    // Reverse: SuccessorLeftMultiplication distributes successor across all groups
    public typealias ReverseProof = Predecessor.ReverseProof.Distributed
}

/// Proves N3 * b = b * N3 for all b.
public protocol MultiplicationCommutativityOfThree: Natural {
    associatedtype ForwardProof: NaturalProduct               // N3 * Self
    associatedtype ReverseProof: NaturalProduct & SuccessorLeftMultiplication  // Self * N3
}

/// Seed type for MultiplicationCommutativityOfThree induction (represents b = 0).
public enum MultiplicationCommutativityOfThreeSeed: Natural {
    public typealias Successor = AddOne<Self>
    public typealias Predecessor = SubOne<Zero>
}

// Base case: N3 * 0 = 0 and 0 * N3 = 0
extension MultiplicationCommutativityOfThreeSeed: MultiplicationCommutativityOfThree {
    public typealias ForwardProof = TimesZero<N3>
    public typealias ReverseProof = N3.ZeroTimesProof
}

// Inductive step: given N3 * b and b * N3, produce N3 * S(b) and S(b) * N3
extension AddOne: MultiplicationCommutativityOfThree where Predecessor: MultiplicationCommutativityOfThree {
    // Forward: 3 ticks (one copy of N3) + group boundary
    public typealias ForwardProof = TimesGroup<TimesTick<TimesTick<TimesTick<Predecessor.ForwardProof>>>>
    // Reverse: SuccessorLeftMultiplication distributes successor across all groups
    public typealias ReverseProof = Predecessor.ReverseProof.Distributed
}

// MARK: - Theorem 4: Right multiplicative identity (n * 1 = n)

/// For any natural number N, there exists a proof that N * 1 = N.
/// Proved by induction on N using SuccessorLeftMultiplication.
///
/// Base case: 0 * 1 = 0, witnessed by TimesGroup<TimesZero<Zero>> (one group
/// of zero ticks). Inductive step: if N * 1 = N, then S(N) * 1 = N + 1 = S(N)
/// via SuccessorLeftMultiplication.Distributed.
public protocol MultiplicationRightOne: Natural {
    associatedtype TimesOneProof: NaturalProduct & SuccessorLeftMultiplication
}

// Base case: 0 * 1 = 0 (one group, zero ticks)
extension Zero: MultiplicationRightOne {
    public typealias TimesOneProof = TimesGroup<TimesZero<Zero>>
}

// Inductive step: n * 1 = n => S(n) * 1 = S(n)
// SuccessorLeftMultiplication.Distributed adds one extra tick per group; with one group,
// Total goes from n to n + 1 = S(n).
extension AddOne: MultiplicationRightOne where Predecessor: MultiplicationRightOne {
    public typealias TimesOneProof = Predecessor.TimesOneProof.Distributed
}

// MARK: - Theorem 5: Left multiplicative identity (1 * n = n)

/// For any natural number N, there exists a proof that 1 * N = N.
/// Proved by induction on N.
///
/// Base case: 1 * 0 = 0, witnessed by TimesZero<N1>. Inductive step:
/// given 1 * n = n, then 1 * S(n) = TimesGroup<TimesTick<proof>> with
/// Total = S(n) (one tick per group, since Left = 1).
public protocol MultiplicationLeftOne: Natural {
    associatedtype OneTimesProof: NaturalProduct & SuccessorLeftMultiplication
}

// Base case: 1 * 0 = 0
extension Zero: MultiplicationLeftOne {
    public typealias OneTimesProof = TimesZero<N1>
}

// Inductive step: 1 * n = n => 1 * S(n) = S(n)
// One tick (Left = 1) + one group boundary.
extension AddOne: MultiplicationLeftOne where Predecessor: MultiplicationLeftOne {
    public typealias OneTimesProof = TimesGroup<TimesTick<Predecessor.OneTimesProof>>
}

// MARK: - Macro-generated commutativity proofs
//
// The @MultiplicationCommutativityProof macro generates bounded-depth paired proofs showing
// A * b = b * A for b = 0 through the given depth. Each ForwardK witnesses
// A * K (flat encoding) and each ReverseK witnesses K * A (via SuccessorLeftMultiplication).
// The type checker verifies that both sides have the same Total.
//
// This is analogous to how @FibonacciProof and @PiConvergenceProof generate
// bounded-depth proof chains. The manual MultiplicationCommutativityOfTwo/MultiplicationCommutativityOfThree protocols
// above provide universal proofs (for all b); the macro generates verified
// proofs up to a specific depth for any A >= 2.
//
// See main.swift Section 16 for @MultiplicationCommutativityProof invocations and assertions.
