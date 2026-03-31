# Future work: inductive proofs, coinductive streams, and irrational numbers

Tracking issue: https://github.com/jakebromberg/type-level-natural-numbers/issues/25

## Context

The project encodes natural numbers as types using the Peano axioms. After the witness-based paradigm shift, arithmetic facts are proved by constructing types whose existence demonstrates the relationship -- `NaturalSum`, `NaturalProduct`, `NaturalLessThan` -- and a successful `swift build` is the proof.

The witness infrastructure currently proves **specific** arithmetic facts: `2 + 3 = 5`, `2 * 3 = 6`, `2 < 5`. Each proof is a concrete type alias naming a chain of witness constructors.

This document explores how to extend the system to prove **universal** arithmetic theorems (statements that hold for all naturals), represent **irrational and transcendental numbers** at the type level, and use **macros** to automate proof construction. It also catalogs the **known limitations** of encoding proofs in Swift's type system.

### Current witness infrastructure

```
Sources/MisuseOfNotation/
  PeanoTypes.swift           -- Integer, Natural, Nonpositive, Zero, AddOne, SubOne, assertEqual
  Witnesses.swift            -- NaturalSum (PlusZero, PlusSucc), NaturalProduct (TimesZero, TimesSucc),
                                NaturalLessThan (ZeroLT, SuccLT)
  TypeLevelArithmetic.swift  -- N0-N9, Sum, Product, _TimesNk protocols
  Macros.swift               -- @ProductConformance declaration
```

### The Curry-Howard dictionary for Swift

The entire approach rests on a correspondence between logic and Swift's type system:

| Logic | Swift encoding |
|---|---|
| Proposition | Protocol (with associated type constraints) |
| Proof | Conformance (struct/enum satisfying the protocol) |
| Universal quantification | Conditional conformance with `where` clause |
| Existential quantification | Associated type |
| Implication P => Q | Protocol inheritance or `where` clause |
| Conjunction P /\ Q | Multiple `where` constraints |
| Structural induction | Base conformance on `Zero` + conditional on `AddOne` |
| Coinduction | Self-referential conformance (fixed point) |
| Proof search | The compiler resolving conformances |

---

## 1. Universal proofs via conditional conformance

### The key insight

Conditional protocol conformance in Swift **is** structural induction. When you write a base case conformance on `Zero` and a conditional conformance on `AddOne<Predecessor> where Predecessor: P`, the compiler can resolve `P` for any concrete natural by chaining from `AddOne` down to `Zero`. This proves a theorem for all naturals without enumerating them.

The codebase already does this with `_TimesN2`:

```swift
extension Zero: _TimesN2 {
    public typealias _TimesN2Result = Zero           // base case: 2*0 = 0
}
extension AddOne: _TimesN2 where Predecessor: _TimesN2 {
    public typealias _TimesN2Result = AddOne<AddOne<Predecessor._TimesN2Result>>  // 2*S(n) = S(S(2*n))
}
```

This is a proof that `forall n, 2*n exists and is computable`. The associated type `_TimesN2Result` is an existential witness -- the compiler resolves it to a concrete type for any natural.

### Theorem: forall n, n + 0 = n (right identity of addition)

Define a protocol whose conformance **is** the proof:

```swift
/// Theorem: forall n: Natural, n + 0 = n.
/// Proof: by structural induction, constructing a NaturalSum witness at each level.
protocol PlusZeroIdentity: Natural {
    associatedtype Proof: NaturalSum
        where Proof.Left == Self, Proof.Right == Zero, Proof.Total == Self
}

extension Zero: PlusZeroIdentity {
    // Base case: 0 + 0 = 0.
    typealias Proof = PlusZero<Zero>
}

extension AddOne: PlusZeroIdentity where Predecessor: PlusZeroIdentity {
    // Inductive case: PlusZero<Self> witnesses Self + 0 = Self for any Natural.
    typealias Proof = PlusZero<Self>
}
```

The `where Proof.Total == Self` constraint is the theorem statement. If Swift accepts the conformance, the proof is valid for all naturals. For any concrete `N7`, the compiler chains through seven conditional conformances down to `Zero`.

### Theorem: forall n, 0 + n = n (left identity of addition)

This is harder -- it requires actual induction because `PlusZero` only covers the right-operand-zero case. The proof must construct different witness chains at each level:

```swift
/// Theorem: forall n: Natural, 0 + n = n.
protocol ZeroPlusIdentity: Natural {
    associatedtype Proof: NaturalSum
        where Proof.Left == Zero, Proof.Right == Self, Proof.Total == Self
}

extension Zero: ZeroPlusIdentity {
    // Base case: 0 + 0 = 0.
    typealias Proof = PlusZero<Zero>
}

extension AddOne: ZeroPlusIdentity where Predecessor: ZeroPlusIdentity {
    // Inductive case: given 0 + n = n (Predecessor.Proof),
    // PlusSucc wraps it to get 0 + S(n) = S(n).
    typealias Proof = PlusSucc<Predecessor.Proof>
}
```

Here the inductive hypothesis (`Predecessor.Proof`) is used in the inductive step (`PlusSucc` wraps it). The compiler verifies that `PlusSucc<Predecessor.Proof>.Total` equals `AddOne<Predecessor.Proof.Total>` equals `AddOne<Predecessor>` equals `Self`.

### Theorem: forall n, n * 0 = 0

```swift
protocol TimesZeroAnnihilates: Natural {
    associatedtype Proof: NaturalProduct
        where Proof.Left == Self, Proof.Right == Zero, Proof.Total == Zero
}

extension Zero: TimesZeroAnnihilates {
    typealias Proof = TimesZero<Zero>
}

extension AddOne: TimesZeroAnnihilates where Predecessor: TimesZeroAnnihilates {
    typealias Proof = TimesZero<Self>
}
```

### Theorem: forall n, n * 1 = n

This requires composing product and sum witnesses at each level:

```swift
protocol TimesOneIdentity: Natural {
    associatedtype Proof: NaturalProduct
        where Proof.Left == Self, Proof.Right == N1, Proof.Total == Self
}
```

The conformances require constructing `TimesSucc<TimesZero<Self>, SumProof>` at each level, where `SumProof` witnesses `0 + Self = Self`. This composes with `ZeroPlusIdentity`. The exact construction depends on how cleanly the `where` constraints compose -- this is one of the first proofs to implement and test.

---

## 2. Coinductive streams for irrational numbers

### The problem

An irrational number has no finite representation as a ratio of naturals. Any type-level encoding of an irrational must be either infinite or schematic. Since Swift types are finite definitions, we need a finite definition that the compiler can unfold to arbitrary depth.

### Self-referential conformance as coinduction

A coinductive type is defined by its **observations** (what you can extract from it), not its **constructors** (how you build it). Swift protocol conformances can reference the conforming type itself, creating a productive fixed point:

```swift
/// A coinductive stream of natural-number coefficients.
protocol CoefficientStream {
    associatedtype Head: Natural
    associatedtype Tail: CoefficientStream
}
```

This looks like it demands infinite unfolding. But Swift resolves associated types **lazily** -- it only follows the chain as far as needed for the current type-checking obligation.

### sqrt(2) = [1; 2, 2, 2, ...]

The continued fraction for sqrt(2) has a repeating tail. A self-referential type encodes this:

```swift
/// The repeating part of sqrt(2)'s continued fraction: [2; 2, 2, ...].
struct Sqrt2Repeat: CoefficientStream {
    typealias Head = N2
    typealias Tail = Sqrt2Repeat    // fixed point
}

/// sqrt(2) = [1; 2, 2, 2, ...]
struct Sqrt2: CoefficientStream {
    typealias Head = N1
    typealias Tail = Sqrt2Repeat
}
```

`Sqrt2Repeat` references itself through its `Tail` associated type. This is valid because there is no stored data, no runtime recursion, and no infinite memory. The compiler records the equation `Sqrt2Repeat.Tail == Sqrt2Repeat` and applies it as many times as needed:

```
Sqrt2.Head                          == N1
Sqrt2.Tail.Head                     == N2
Sqrt2.Tail.Tail.Head                == N2
Sqrt2.Tail.Tail.Tail.Head           == N2
...
```

### e = [2; 1, 2, 1, 1, 4, 1, 1, 6, ...]

The continued fraction for e has a parameterized repeating pattern. After the initial coefficient of 2, it repeats `(1, 1, 2k)` for k = 1, 2, 3, ...:

```swift
struct ERepeat<K: Natural>: CoefficientStream where K: _TimesN2 {
    typealias Head = N1
    typealias Tail = ERepeat1<K>
}
struct ERepeat1<K: Natural>: CoefficientStream where K: _TimesN2 {
    typealias Head = N1
    typealias Tail = ERepeat2<K>
}
struct ERepeat2<K: Natural>: CoefficientStream where K: _TimesN2 {
    typealias Head = K._TimesN2Result       // coefficient 2k
    typealias Tail = ERepeat<AddOne<K>>     // advance k, loop back
}

struct EulerCF: CoefficientStream {
    typealias Head = N2
    typealias Tail = ERepeat<N1>            // k starts at 1
}
```

This encodes the complete infinite continued fraction for e. Each unfolding advances `K` by one successor, producing the next triple `(1, 1, 2(k+1))`.

### The golden ratio: phi = [1; 1, 1, 1, ...]

The simplest possible coinductive irrational:

```swift
struct PhiCF: CoefficientStream {
    typealias Head = N1
    typealias Tail = PhiCF      // all coefficients are 1
}
```

### Algebraic irrationals via inequality witnesses

Independent of continued fractions, we can bracket an irrational using existing witness types. sqrt(2) is defined by x^2 = 2, so for any rational approximation a/b, we can prove whether a^2 < 2*b^2 or a^2 > 2*b^2 using `NaturalProduct` and `NaturalLessThan`:

```swift
/// Witness that A/B < sqrt(2), i.e. A^2 < 2*B^2.
protocol Sqrt2LowerBound {
    associatedtype A: Natural
    associatedtype B: Natural
    associatedtype ASquared: NaturalProduct where ASquared.Left == A, ASquared.Right == A
    associatedtype BSquared: NaturalProduct where BSquared.Left == B, BSquared.Right == B
    associatedtype TwoBSq: NaturalSum where TwoBSq.Left == BSquared.Total, TwoBSq.Right == BSquared.Total
    associatedtype Bound: NaturalLessThan where Bound.Left == ASquared.Total, Bound.Right == TwoBSq.Total
}
```

Constructing a conforming type proves the bound. The proof composes product and comparison witnesses that already exist.

---

## 3. Convergent computation: combining induction and coinduction

The payoff is connecting coinductive streams (infinite representations) to inductive convergent computations (finite proofs about those representations).

### Convergent witnesses

Define a witness that a continued fraction stream has a specific rational convergent at a given depth:

```swift
/// Witness that a continued fraction has convergent P/Q at depth N.
/// Uses the standard recurrence: p_n = a_n * p_{n-1} + p_{n-2}.
protocol Convergent {
    associatedtype Stream: CoefficientStream
    associatedtype Depth: Natural
    associatedtype P: Natural       // numerator of convergent
    associatedtype Q: Natural       // denominator of convergent
}

/// Base case (depth 0): convergent of [a; ...] is a/1.
struct ConvBase<S: CoefficientStream>: Convergent {
    typealias Stream = S
    typealias Depth = N0
    typealias P = S.Head
    typealias Q = N1
}
```

Each inductive step peels one coefficient from the stream, computes the recurrence using `NaturalProduct` and `NaturalSum` witnesses, and advances the depth counter. The stream is coinductive (infinite), but the convergent computation is structural induction (finite depth). They meet at the interface.

### Proving convergent bounds

For sqrt(2), we can combine convergent computation with the inequality witness from section 2 to prove: "the depth-n convergent of [1; 2, 2, ...] satisfies p^2 < 2*q^2." This would be an inductive proof over depth, using the `Sqrt2LowerBound` protocol at each level.

---

## 4. Macro-automated proof construction

### The problem

Witness chains grow quadratically. The proof of `2 * 3 = 6` requires 3 `TimesSucc` steps, each containing a `NaturalSum` chain of length proportional to the running total. For larger numbers, manual construction is impractical.

### Generalizing @ProductConformance

The existing `@ProductConformance(n)` macro generates inductive protocols and conformances for multiplication by a fixed n. This pattern generalizes to arbitrary proof generation:

**`@InductiveProof`**: Given a theorem schema and a Peano axiom structure, emit the full protocol + conformance chain. For example:

```swift
@InductiveProof("forall n, n + 0 = n", base: .plusZero, step: .plusZero)
```

could generate the `PlusZeroIdentity` protocol, `Zero` conformance, and `AddOne` conditional conformance.

**`@WitnessChain(lhs * rhs)`**: Given a specific arithmetic expression, emit the chain of `typealias` declarations that constitute the proof. For example, `@WitnessChain(4 * 5)` would emit the `TimesZero`, `PlusSucc`, `TimesSucc` chain proving 4 * 5 = 20.

**`@ContinuedFractionConvergent(sqrt: 2, depth: 10)`**: Emit the full `ConvStep` chain computing the depth-10 convergent of sqrt(2), along with the `Sqrt2LowerBound` proof that it brackets the irrational.

### Architecture

The macro plugin (`MisuseOfNotationMacros`) already has the infrastructure: `ProductConformanceMacro.swift` shows how to generate protocol definitions, conformances, and constrained extensions from a single attribute. New proof macros would follow the same pattern, using `peanoTypeName(for:)` to emit type names and building witness chains programmatically.

The macro is the **tactics engine** (automates proof construction). The type checker is the **kernel** (verifies correctness). This mirrors the architecture of proof assistants like Lean and Coq.

---

## 5. Known limitations

These are fundamental constraints of Swift's type system that cannot be overcome with the techniques described above.

### 5.1 No proof by contradiction

Swift's type system can only **construct** witnesses. It cannot derive that no witness exists. This means:

- **Cannot prove sqrt(2) is irrational.** The classical proof assumes p/q = sqrt(2) with gcd(p,q)=1 and derives a contradiction. Swift's conformance system has no mechanism for contradiction or negation.
- **Cannot prove any number is transcendental.** Transcendence proofs require showing that no polynomial with integer coefficients has the number as a root, which is an inherently negative statement.
- **Cannot prove two types are unequal.** There is no "not equal" witness analogous to `assertEqual`. Swift can reject a conformance that requires equal types when they aren't, but it cannot express "these types differ" as a provable proposition.

### 5.2 No universal quantification over two or more variables

A single conditional conformance on `AddOne where Predecessor: P` gives induction over one variable. For theorems like:

- `forall n m, n + m = m + n` (commutativity)
- `forall n m k, (n + m) + k = n + (m + k)` (associativity)

you need nested induction: for each fixed m, prove by induction on n. This requires a **two-parameter protocol** where both parameters range over all naturals. In principle:

```swift
protocol Commutative {
    associatedtype N: Natural
    associatedtype M: Natural
    associatedtype LR: NaturalSum where LR.Left == N, LR.Right == M
    associatedtype RL: NaturalSum where RL.Left == M, RL.Right == N
    // Need: LR.Total == RL.Total
}
```

But there is no way to have `AddOne` conditionally conform to this for all values of `M` simultaneously. Each conditional conformance fixes the structure of one generic parameter, not two. We would need a protocol parameterized by both, which Swift protocols do not support.

**Partial solution (ProofSeed)**: The `ProofSeed` technique solves the two-variable problem for associativity. `ProofSeed<P>` wraps a `NaturalSum` proof as a `Natural`, and `AddAssociative` does induction over `AddOne` layers on top. Given P witnessing `a + b = d`, `AddOne^c(ProofSeed<P>).AssocProof = PlusSucc^c(P)` witnesses `a + (b + c) = d + c`. Universality is parametric over P (any proof) and inductive over c (any natural). This avoids the two-parameter protocol problem by encoding one axis as a type parameter and inducting over the other.

**Remaining limitation**: A macro could generate conformances for all pairs up to a fixed bound, giving a finite approximation to the universal statement. This is not a proof for all naturals, but it could catch errors in the formulation.

### 5.3 No negative reasoning or case analysis

Swift's conformance system cannot branch on whether a type matches a specific form. There is no way to write:

```swift
// NOT valid Swift
extension SomeType where N == Zero { ... }
extension SomeType where N != Zero { ... }  // no "not equal" constraint
```

You can only match the **positive** case (`N == Zero`) or the **structural** case (`N == AddOne<Predecessor>`). This precludes proof by cases except when the cases are expressed as separate conformances, and well-founded induction on non-structural orderings.

### 5.4 Type checker recursion limits

The Swift compiler has a finite recursion depth for conformance resolution (typically around 256 or 1024 depending on the version). This means:

- Proofs involving naturals larger than a few hundred may fail to compile.
- Deeply nested witness chains (e.g., convergent computations at depth 20+) may exceed the limit even for small numbers.
- The exact limit is an implementation detail and may vary across Swift versions.

### 5.5 No higher-order quantification

We cannot state or prove theorems about **all** theorems, or about the proof system itself. For example:

- "If P(0) and (P(n) => P(n+1)), then P(n) for all n" -- this is the induction **principle**, and it's built into Swift's conformance resolution, but it cannot be stated or proved within the system.
- "NaturalSum is total" (every pair of naturals has a sum) -- this requires quantifying over a protocol, which Swift cannot do.

### 5.6 No coinductive proof verification

While coinductive *definitions* (self-referential conformances) work, the compiler cannot verify coinductive *proofs*. It can check that `Sqrt2Repeat` conforms to `CoefficientStream`, but it cannot verify that the stream it defines actually converges to sqrt(2). That property must be established by external mathematical reasoning, with the type system only verifying the mechanical steps (each convergent bracket is correct).

---

## 6. Implementation roadmap

Ordered by dependency and increasing complexity:

1. **Universal identity proofs** (section 1): `PlusZeroIdentity`, `ZeroPlusIdentity`, `TimesZeroAnnihilates`. These validate the conditional-conformance-as-induction technique with minimal new infrastructure.

2. **Coinductive stream protocol and basic irrationals** (section 2): `CoefficientStream`, `Sqrt2`, `PhiCF`, `EulerCF`. Pure type definitions with no new witness machinery needed -- validates self-referential conformance.

3. **Rational pairs and inequality brackets** (section 2): `Sqrt2LowerBound`, `Sqrt2UpperBound`. Composes existing witnesses in new protocols.

4. **Convergent witnesses** (section 3): `Convergent`, `ConvBase`, `ConvStep`. Connects coinductive streams to inductive computation.

5. **Proof macros** (section 4): `@WitnessChain`, `@InductiveProof`, `@ContinuedFractionConvergent`. Automates construction of deep witness chains.

6. **`TimesOneIdentity` and harder universal proofs** (section 1): Proofs that compose multiple witness types and require the compiler to resolve multi-step constraint chains.

---

## References

- Peano axioms: https://en.wikipedia.org/wiki/Peano_axioms
- Curry-Howard correspondence: https://en.wikipedia.org/wiki/Curry%E2%80%93Howard_correspondence
- Continued fractions: https://en.wikipedia.org/wiki/Continued_fraction
- Coinduction: https://en.wikipedia.org/wiki/Coinduction
- Swift conditional conformances: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0143-conditional-conformances.md
