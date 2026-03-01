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
public protocol MulLeftZero: Natural {
    associatedtype ZeroTimesProof: NaturalProduct & SuccLeftMul
}

// Base case: 0 * 0 = 0
extension Zero: MulLeftZero {
    public typealias ZeroTimesProof = TimesZero<Zero>
}

// Inductive step: if 0 * n = 0, then 0 * S(n) = 0
// Each group has 0 ticks (Left = 0), so just wrap with TimesGroup.
extension AddOne: MulLeftZero where Predecessor: MulLeftZero {
    public typealias ZeroTimesProof = TimesGroup<Predecessor.ZeroTimesProof>
}

// MARK: - Theorem 2: Successor-left multiplication (a * b = c => S(a) * b = c + b)

/// For any flat multiplication proof that a * b = c, there exists a proof
/// that S(a) * b = c + b. Each TimesGroup gains one extra TimesTick
/// (the new successor contributes one extra unit per copy), so b groups
/// contribute b extra ticks: Total goes from c to c + b.
///
/// Structurally identical to how SuccLeftAdd wraps each PlusSucc.
public protocol SuccLeftMul: NaturalProduct {
    associatedtype Distributed: NaturalProduct & SuccLeftMul
}

// Base case: TimesZero<N> witnesses N * 0 = 0
// S(N) * 0 = 0, witnessed by TimesZero<S(N)>
extension TimesZero: SuccLeftMul {
    public typealias Distributed = TimesZero<AddOne<N>>
}

// Inductive step (tick): TimesTick<P> witnesses a * b = S(c) where P: a * b' = c
// If P.Distributed witnesses S(a) * b' = d,
// then TimesTick<P.Distributed> witnesses S(a) * b = S(d)
extension TimesTick: SuccLeftMul where Proof: SuccLeftMul {
    public typealias Distributed = TimesTick<Proof.Distributed>
}

// Inductive step (group): TimesGroup<P> witnesses a * S(b) = c where P: a * b = c
// If P.Distributed witnesses S(a) * b = d,
// then TimesGroup<TimesTick<P.Distributed>> witnesses S(a) * S(b) = S(d)
// The extra TimesTick accounts for the new successor's contribution to this group.
extension TimesGroup: SuccLeftMul where Proof: SuccLeftMul {
    public typealias Distributed = TimesGroup<TimesTick<Proof.Distributed>>
}

// MARK: - Theorem 3: Commutativity (a * b = b * a, per fixed A)

// For each fixed A, _MulCommNk proves A * b = b * A for all b by induction on b:
//   Base (b=0): A * 0 = 0 (TimesZero) and 0 * A = 0 (MulLeftZero). Both Total = 0.
//   Step (b → S(b)):
//     Forward (A * S(b)): add A-many TimesTicks + TimesGroup to previous A * b proof.
//     Reverse (S(b) * A): apply SuccLeftMul to previous b * A proof.
//
// The forward side hardcodes A ticks per group (hence per-A protocols). The reverse
// side chains universally because SuccLeftMul.Distributed: SuccLeftMul (strengthened).
//
// Full universality (for all a AND b) is not expressible in Swift's current type system
// due to the lack of generic associated types. Each _MulCommNk is universal over b.

/// Proves N2 * b = b * N2 for all b.
public protocol _MulCommN2: Natural {
    associatedtype FwdProof: NaturalProduct               // N2 * Self
    associatedtype RevProof: NaturalProduct & SuccLeftMul  // Self * N2
}

/// Seed type for _MulCommN2 induction (represents b = 0).
public enum _MulCommN2Seed: Natural {
    public typealias Successor = AddOne<Self>
    public typealias Predecessor = SubOne<Zero>
}

// Base case: N2 * 0 = 0 and 0 * N2 = 0
extension _MulCommN2Seed: _MulCommN2 {
    public typealias FwdProof = TimesZero<N2>
    public typealias RevProof = N2.ZeroTimesProof
}

// Inductive step: given N2 * b and b * N2, produce N2 * S(b) and S(b) * N2
extension AddOne: _MulCommN2 where Predecessor: _MulCommN2 {
    // Forward: 2 ticks (one copy of N2) + group boundary
    public typealias FwdProof = TimesGroup<TimesTick<TimesTick<Predecessor.FwdProof>>>
    // Reverse: SuccLeftMul distributes successor across all groups
    public typealias RevProof = Predecessor.RevProof.Distributed
}

/// Proves N3 * b = b * N3 for all b.
public protocol _MulCommN3: Natural {
    associatedtype FwdProof: NaturalProduct               // N3 * Self
    associatedtype RevProof: NaturalProduct & SuccLeftMul  // Self * N3
}

/// Seed type for _MulCommN3 induction (represents b = 0).
public enum _MulCommN3Seed: Natural {
    public typealias Successor = AddOne<Self>
    public typealias Predecessor = SubOne<Zero>
}

// Base case: N3 * 0 = 0 and 0 * N3 = 0
extension _MulCommN3Seed: _MulCommN3 {
    public typealias FwdProof = TimesZero<N3>
    public typealias RevProof = N3.ZeroTimesProof
}

// Inductive step: given N3 * b and b * N3, produce N3 * S(b) and S(b) * N3
extension AddOne: _MulCommN3 where Predecessor: _MulCommN3 {
    // Forward: 3 ticks (one copy of N3) + group boundary
    public typealias FwdProof = TimesGroup<TimesTick<TimesTick<TimesTick<Predecessor.FwdProof>>>>
    // Reverse: SuccLeftMul distributes successor across all groups
    public typealias RevProof = Predecessor.RevProof.Distributed
}

// MARK: - Theorem 4: Right multiplicative identity (n * 1 = n)

/// For any natural number N, there exists a proof that N * 1 = N.
/// Proved by induction on N using SuccLeftMul.
///
/// Base case: 0 * 1 = 0, witnessed by TimesGroup<TimesZero<Zero>> (one group
/// of zero ticks). Inductive step: if N * 1 = N, then S(N) * 1 = N + 1 = S(N)
/// via SuccLeftMul.Distributed.
public protocol MulRightOne: Natural {
    associatedtype TimesOneProof: NaturalProduct & SuccLeftMul
}

// Base case: 0 * 1 = 0 (one group, zero ticks)
extension Zero: MulRightOne {
    public typealias TimesOneProof = TimesGroup<TimesZero<Zero>>
}

// Inductive step: n * 1 = n => S(n) * 1 = S(n)
// SuccLeftMul.Distributed adds one extra tick per group; with one group,
// Total goes from n to n + 1 = S(n).
extension AddOne: MulRightOne where Predecessor: MulRightOne {
    public typealias TimesOneProof = Predecessor.TimesOneProof.Distributed
}

// MARK: - Theorem 5: Left multiplicative identity (1 * n = n)

/// For any natural number N, there exists a proof that 1 * N = N.
/// Proved by induction on N.
///
/// Base case: 1 * 0 = 0, witnessed by TimesZero<N1>. Inductive step:
/// given 1 * n = n, then 1 * S(n) = TimesGroup<TimesTick<proof>> with
/// Total = S(n) (one tick per group, since Left = 1).
public protocol MulLeftOne: Natural {
    associatedtype OneTimesProof: NaturalProduct & SuccLeftMul
}

// Base case: 1 * 0 = 0
extension Zero: MulLeftOne {
    public typealias OneTimesProof = TimesZero<N1>
}

// Inductive step: 1 * n = n => 1 * S(n) = S(n)
// One tick (Left = 1) + one group boundary.
extension AddOne: MulLeftOne where Predecessor: MulLeftOne {
    public typealias OneTimesProof = TimesGroup<TimesTick<Predecessor.OneTimesProof>>
}

// MARK: - Macro-generated commutativity proofs
//
// The @MulCommProof macro generates bounded-depth paired proofs showing
// A * b = b * A for b = 0 through the given depth. Each _FwdK witnesses
// A * K (flat encoding) and each _RevK witnesses K * A (via SuccLeftMul).
// The type checker verifies that both sides have the same Total.
//
// This is analogous to how @FibonacciProof and @PiConvergenceProof generate
// bounded-depth proof chains. The manual _MulCommN2/_MulCommN3 protocols
// above provide universal proofs (for all b); the macro generates verified
// proofs up to a specific depth for any A >= 2.
//
// See main.swift Section 16 for @MulCommProof invocations and assertions.
