# Abuse of Notation

Encoding the natural numbers as Swift types using the Peano axioms, with witness-based proofs that verify arithmetic facts at compile time. A successful `swift build` is the proof.

## Peano encoding

Numbers are represented as types:

- `Zero` represents 0
- `AddOne<N>` represents the successor of N (i.e. N + 1)
- `SubOne<N>` represents the predecessor of N (i.e. N - 1)

For example, `AddOne<AddOne<Zero>>` is the type-level representation of 2, and `SubOne<Zero>` is -1. Type aliases `N0` through `N9` provide convenient shorthand.

## Protocols

The protocol hierarchy uses 3 protocols:

### `Integer`

The root protocol for all integer types. Declares `Successor` and `Predecessor` associated types.

### `Natural`

Extends `Integer` for nonnegative integers (0, 1, 2, ...). Constrains `Successor` to `Natural`. Conformed to by `Zero` and `AddOne<N>`.

### `Nonpositive`

Extends `Integer` for nonpositive integers (0, -1, -2, ...). Constrains `Predecessor` to `Nonpositive`. Conformed to by `Zero` and `SubOne<N>`.

`Zero` sits at the intersection of `Natural` and `Nonpositive`, conforming to both.

## Witness-based proofs

Arithmetic facts are proved by constructing types whose existence demonstrates the relationship. The proofs are verified by the Swift type checker at compile time.

### Addition witnesses (`NaturalSum`)

The `NaturalSum` protocol witnesses that `Left + Right = Total`:

- `PlusZero<N>`: proves `N + 0 = N` (base case)
- `PlusSucc<Proof>`: if `A + B = C`, proves `A + S(B) = S(C)` (inductive step)

```swift
// Proof that 2 + 3 = 5
typealias TwoPlusThree = PlusSucc<PlusSucc<PlusSucc<PlusZero<N2>>>>
assertEqual(TwoPlusThree.Total.self, N5.self)  // compiles only if correct
```

### Multiplication witnesses (`NaturalProduct`)

The `NaturalProduct` protocol witnesses that `Left * Right = Total`:

- `TimesZero<N>`: proves `N * 0 = 0` (base case)
- `TimesSucc<MulProof, AddProof>`: if `A * B = C` and `C + A = D`, proves `A * S(B) = D` (inductive step)

```swift
// Proof that 2 * 3 = 6
// Chain: 2*0=0, 0+2=2 so 2*1=2, 2+2=4 so 2*2=4, 4+2=6 so 2*3=6
typealias Mul2x0 = TimesZero<N2>
typealias Add0p2 = PlusSucc<PlusSucc<PlusZero<N0>>>
typealias Mul2x1 = TimesSucc<Mul2x0, Add0p2>
typealias Add2p2 = PlusSucc<PlusSucc<PlusZero<N2>>>
typealias Mul2x2 = TimesSucc<Mul2x1, Add2p2>
typealias Add4p2 = PlusSucc<PlusSucc<PlusZero<N4>>>
typealias Mul2x3 = TimesSucc<Mul2x2, Add4p2>
assertEqual(Mul2x3.Total.self, N6.self)
```

### Comparison witnesses (`NaturalLessThan`)

The `NaturalLessThan` protocol witnesses that `Left < Right`:

- `ZeroLT<N>`: proves `0 < S(N)`
- `SuccLT<Proof>`: if `A < B`, proves `S(A) < S(B)`

```swift
// Proof that 2 < 5 (peel off 2 successors, then 0 < 3)
typealias TwoLtFive = SuccLT<SuccLT<ZeroLT<N2>>>
```

### Type-level arithmetic (`Sum`, `Product`)

For convenience, `Sum<L, R>.Result` and `Product<L, R>.Result` compute type-level addition and multiplication via constrained extensions:

```swift
assertEqual(Sum<N2, N3>.Result.self, N5.self)
assertEqual(Product<N2, N3>.Result.self, N6.self)
```

The `@ProductConformance(n)` macro generates the inductive protocols and conformances needed for `Product` to handle a given multiplier.

## Macros as proof generators

Writing witness chains by hand is explicit but tedious -- a proof of `F(10) = 55` requires threading 10 `PlusSucc`/`PlusZero` witnesses through `FibStep` chains. Swift macros automate this by computing arithmetic at compile time and emitting the witness types that the type checker independently verifies.

The architecture has three layers:

1. **Protocol** (human-authored) -- states the theorem (e.g., `FibVerified` requires `SumWitness` proving `Prev + Current = Next`)
2. **Macro** (proof search) -- computes integers at compile time and emits witness chains as typealiases
3. **Type checker** (proof verifier) -- structurally verifies every `where` constraint. If the macro emits a wrong witness, compilation fails.

Both proof-generating macros use `@attached(member, names: arbitrary)`, generating all witnesses as members of a namespace enum:

```swift
@FibonacciProof(upTo: 10)
enum FibProof {}

assertEqual(FibProof._Fib5.Current.self, N5.self)  // F(5) = 5
assertEqual(FibProof._Fib6.Current.self, N8.self)  // F(6) = 8
```

## A split dependent type system

A dependent type is a type that depends on a value -- `Vec(n, A)` is the canonical example. A dependent type checker unifies two roles: a **normalizer** that evaluates expressions inside types and a **verifier** that checks structural constraints. This project splits those roles across two compilation phases.

**The macro is the normalizer.** It is a Turing-complete program that evaluates arithmetic, computes CF convergents, Fibonacci numbers, Wallis partial products -- arbitrary Swift at compile time. It emits witness types as typealiases.

**The type checker is the verifier.** It structurally checks every `where` constraint, every associated type resolution, every `assertEqual` unification. It cannot be fooled by the macro: a wrong macro emits wrong witnesses; the type checker rejects them.

The separation is a feature. The normalizer can compute anything, but the verifier only accepts structurally valid witnesses. Universal theorems (addition commutativity, multiplication left-zero) are the verifier alone -- no macro needed, because conditional conformance IS structural induction. Bounded proofs (pi convergence, Fibonacci, Wallis) require normalizer + verifier together, because the arithmetic depends on the depth.

## Limitations and the universality gap

The CF recurrence `h_{n+1} = a_n * h_n + h_{n-1}` requires the coefficient `a_n` to depend on the depth `n`. A full dependent type system would normalize `a_n` at abstract `n`; Swift's type checker cannot. Coinductive streams encode the *identity* of an irrational number (its coefficient sequence) but not the *computation* of convergents from that sequence.

Universal theorems work when the inductive step is structurally uniform -- the same operation at every depth. `AddCommutative` applies the same `SuccLeftAdd` transformation at each inductive step regardless of the proof's shape. Bounded proofs are needed when the step varies: different CF coefficients at each depth, different Wallis factors at each step, different Fibonacci sums at each level.

This is the precise boundary between what Swift's type system can prove universally (via conditional conformance as structural induction) and what requires macro assistance (via compile-time computation as normalization).

## Cayley-Dickson construction

The Cayley-Dickson construction builds higher-dimensional algebras from pairs. The type-level representation `CayleyDickson<Re, Im>` encodes the structure:

| Level | Algebra | Dimensions |
|-------|---------|------------|
| 0 | Integers | 1 |
| 1 | Gaussian integers | 2 |
| 2 | Quaternions | 4 |
| 3 | Octonions | 8 |

Integer types (`Zero`, `AddOne`, `SubOne`) conform to the `Algebra` marker protocol as level-0 scalars.

## Continued fractions and pi

Two classical formulas approximate pi from opposite directions:

- **Brouncker's continued fraction** for 4/pi: `1 + 1/(2 + 9/(2 + 25/(2 + ...)))`
- **Leibniz series** for pi/4: `1 - 1/3 + 1/5 - 1/7 + ...`

At every depth n, the CF convergent h_n/k_n equals 1/S_{n+1}, where S_{n+1} is the (n+1)-th Leibniz partial sum. The `@PiConvergenceProof(depth:)` macro constructs both sequences independently -- `GCFConvergent` for CF convergents via the standard recurrence, `LeibnizPartialSum` for alternating series via fraction arithmetic -- plus all intermediate product and sum witnesses, then generates `assertEqual` calls to verify the correspondence:

```swift
@PiConvergenceProof(depth: 3)
enum PiProof {}

// CF convergent h_2/k_2 = 15/13 is the reciprocal of Leibniz S_3 = 13/15
assertEqual(PiProof._CF2.P.self, PiProof._LS3.Q.self)  // 15 = 15
assertEqual(PiProof._CF2.Q.self, PiProof._LS3.P.self)  // 13 = 13
```

Since both sequences converge and their values agree at every depth, they converge to the same limit. The compilation itself is the proof.

## Wallis product

The Wallis product provides a third construction of pi:

```
pi/2 = prod_{k=1}^{inf} (2k)^2 / ((2k-1)(2k+1))
```

Unreduced partial products: W_0 = 1/1, W_1 = 4/3, W_2 = 64/45. Each step multiplies the numerator by (2k)^2 and the denominator by (2k-1)(2k+1). The structural fingerprint: at each step, the numerator factor exceeds the denominator factor by exactly 1:

```
(2k)^2 = (2k-1)(2k+1) + 1
```

This difference-of-squares identity is provable at the type level via a `PlusSucc<PlusZero<...>>` witness. The `@WallisProductProof(depth:)` macro uses a two-step product decomposition (multiplying by 2k twice rather than (2k)^2 once) to keep factor sizes manageable:

```swift
@WallisProductProof(depth: 2)
enum WallisProof {}

assertEqual(WallisProof._W1.P.self, N4.self)   // W_1 numerator = 4
assertEqual(WallisProof._W1.Q.self, N3.self)   // W_1 denominator = 3
```

The macro also emits a factor correspondence check proving (2k-1)(2k+1) + 1 = (2k)^2 at each depth. The proof is self-contained: `WallisStep` constraints verify each multiplication, and the factor correspondence proves the difference-of-squares identity.

## Golden ratio and Fibonacci

The golden ratio phi = (1 + sqrt(5))/2 has the simplest continued fraction: [1; 1, 1, 1, ...]. The CF recurrence with a=1, b=1 is just h_n = h_{n-1} + h_{n-2} -- the Fibonacci recurrence. The `@GoldenRatioProof(depth:)` macro proves that h_n = F(n+2) and k_n = F(n+1) by constructing both Fibonacci witness chains and CF convergents independently, then asserting type equality:

```swift
@GoldenRatioProof(depth: 5)
enum GoldenRatioProof {}

assertEqual(GoldenRatioProof._CF5.P.self, N13.self)  // h_5 = 13 = F(7)
assertEqual(GoldenRatioProof._CF5.Q.self, N8.self)   // k_5 = 8  = F(6)
```

## Universal addition theorems

The proofs above are depth-bounded: macros generate witness chains for specific values. Universal theorems, by contrast, hold for ALL natural numbers. The proof mechanism is conditional conformance -- Swift's version of structural induction.

Each theorem is a protocol with a plain associated type (no `where` clauses, following the `_TimesNk` pattern). The base-case conformance on `Zero`/`PlusZero` and the inductive-step conformance on `AddOne`/`PlusSucc` together prove the property for every natural number or every addition proof.

### Left zero identity: `0 + n = n`

`PlusZero<N>` proves `N + 0 = N`, but `0 + N = N` requires induction on N:

```swift
// AddLeftZero: for any N, there is a NaturalSum witnessing 0 + N = N
extension Zero: AddLeftZero { ... }                         // base case
extension AddOne: AddLeftZero where Predecessor: AddLeftZero { ... }  // inductive step
```

### Successor-left shift: `a + b = c => S(a) + b = S(c)`

The existing `PlusSucc` adds a successor on the right. This theorem shifts a successor on the left:

```swift
// SuccLeftAdd: for any proof P of a + b = c, there is a proof of S(a) + b = S(c)
extension PlusZero: SuccLeftAdd { ... }                     // base case
extension PlusSucc: SuccLeftAdd where Proof: SuccLeftAdd { ... }  // inductive step
```

### Commutativity: `a + b = c => b + a = c`

Combines the first two theorems. The base case uses left zero identity; the inductive step uses successor-left shift:

```swift
// AddCommutative: for any proof P of a + b = c, there is a proof of b + a = c
extension PlusZero: AddCommutative where N: AddLeftZero { ... }   // base case
extension PlusSucc: AddCommutative
    where Proof: AddCommutative, Proof.Commuted: SuccLeftAdd { ... }  // inductive step
```

### Associativity: `(a + b) + c = a + (b + c)`

Associativity is a binary theorem requiring two addition proofs (one for `a + b`, one for the result plus `c`). Swift protocols can only do induction on one type parameter. The `ProofSeed` technique solves this by encoding one proof as a seed type and doing induction on the other:

```swift
// ProofSeed<P>: a Natural wrapping a NaturalSum proof as a base case
// AddAssociative: for any chain AddOne^c(ProofSeed<P>), the AssocProof is PlusSucc^c(P)
typealias Assoc3p2p4 = AddOne<AddOne<AddOne<AddOne<ProofSeed<ThreePlusTwo>>>>>
// AssocProof witnesses 3 + 6 = 9 (i.e. 3 + (2+4) = (3+2) + 4)
assertEqual(Assoc3p2p4.AssocProof.Total.self, N9.self)
```

Universality is twofold: parametric over the seed proof (any `NaturalSum`) and inductive over the extension depth (any natural number).

## Universal multiplication theorems

Unlike the addition theorems (which compose freely because `PlusSucc` has no where clauses), multiplication theorems face a composition obstacle: `TimesSucc` has where clauses that trigger rewrite system explosion when used in inductive protocols. The flat encoding (`TimesTick`/`TimesGroup`) solves this by decomposing each multiplication step into individual successor operations, like `PlusSucc` does for addition:

- **`TimesTick<P>`**: adds 1 to Total (one successor within a "copy of Left"). No where clauses.
- **`TimesGroup<P>`**: adds 1 to Right (one complete copy of Left added). No where clauses.

For `a * b`, the proof has b groups of a ticks each. The flat encoding and `TimesSucc` coexist -- both conform to `NaturalProduct`.

### Left zero annihilation: `0 * n = 0`

With Left = 0, each group has 0 ticks, so the inductive step is just `TimesGroup` wrapping the previous proof:

```swift
// MulLeftZero: for any N, there is a NaturalProduct witnessing 0 * N = 0
extension Zero: MulLeftZero { ... }                         // base case
extension AddOne: MulLeftZero where Predecessor: MulLeftZero { ... }  // inductive step
```

### Successor-left multiplication: `a * b = c => S(a) * b = c + b`

Each `TimesGroup` gains one extra `TimesTick`, so b groups contribute b extra ticks. Structurally identical to how `SuccLeftAdd` wraps each `PlusSucc`:

```swift
// SuccLeftMul: for any flat proof P of a * b = c, there is a proof of S(a) * b = c + b
extension TimesZero: SuccLeftMul { ... }                    // base case
extension TimesTick: SuccLeftMul where Proof: SuccLeftMul { ... }  // tick step
extension TimesGroup: SuccLeftMul where Proof: SuccLeftMul { ... }  // group step (inserts extra tick)
```

### Commutativity: `a * b = b * a` (per fixed A)

Unlike addition commutativity (which transforms a single proof), multiplication commutativity must relate two structurally different proofs: `a * b` has b groups of a ticks, while `b * a` has a groups of b ticks. Swift's type system (lacking generic associated types) cannot express a universal transformation over both a and b simultaneously.

The solution decomposes commutativity into per-A protocols following the `_TimesNk` pattern. For each fixed A, the `_MulCommNk` protocol proves `A * b = b * A` for all b by paired induction:

```swift
// _MulCommN2: proves 2 * b = b * 2 for all b
// FwdProof constructs 2 * S(b) from 2 * b (2 ticks + group)
// RevProof constructs S(b) * 2 from b * 2 (SuccLeftMul.Distributed)
typealias MulComm2x3 = AddOne<AddOne<AddOne<_MulCommN2Seed>>>
assertEqual(MulComm2x3.FwdProof.Total.self, N6.self)  // 2 * 3 = 6
assertEqual(MulComm2x3.RevProof.Total.self, N6.self)  // 3 * 2 = 6
```

The reverse direction chains universally because `SuccLeftMul.Distributed` is itself required to conform to `SuccLeftMul` (a strengthened self-referential constraint). The forward direction hardcodes A ticks per group, hence the per-A protocol structure.

### Macro-generated commutativity proofs

The `@MulCommProof(leftOperand: A, depth: D)` macro automates bounded-depth commutativity proofs for any A >= 2. It generates paired forward/reverse proof chains inside a namespace enum:

```swift
@MulCommProof(leftOperand: 4, depth: 5)
enum MulComm4 {}

assertEqual(MulComm4._Fwd3.Total.self, MulComm4._Rev3.Total.self)  // 4*3 = 3*4
assertEqual(MulComm4._Fwd3.Total.self, N12.self)                    // = 12
```

Each `_FwdK` witnesses `A * K` using the flat encoding (A ticks per group), and each `_RevK` witnesses `K * A` via `SuccLeftMul.Distributed`. The type checker verifies that both Totals match at every depth.

### Distributivity: `a * (b + c) = a*b + a*c`

Distributivity bridges the sum and product witness systems. The flat encoding makes it natural: `a * (b + c)` has `(b + c)` groups of `a` ticks, which is `b` groups (the `a*b` part) followed by `c` groups (the `a*c` part).

`ProductSeed<Q>` wraps an existing product proof `Q` (for `a*b`), analogous to `ProofSeed<P>` for addition associativity. TimesTick/TimesGroup layers on top represent `a*c`. The `MulDistributive` protocol tracks a `NaturalSum` witness (`DistrSum`) through the product proof:

```swift
// 2 * (1 + 1) = 2*1 + 2*1 = 2 + 2 = 4
// Start with FlatMul2x1 (2*1 = 2), add 1 group of 2 ticks.
typealias Distr2x1p1 = TimesGroup<TimesTick<TimesTick<ProductSeed<FlatMul2x1>>>>

assertEqual(Distr2x1p1.Total.self, N4.self)             // 2 * 2 = 4
assertEqual(Distr2x1p1.DistrSum.Left.self, N2.self)     // a*b = 2
assertEqual(Distr2x1p1.DistrSum.Right.self, N2.self)    // a*c = 2
assertEqual(Distr2x1p1.DistrSum.Total.self, N4.self)    // 2 + 2 = 4
```

Each `TimesTick` wraps `DistrSum` in `PlusSucc` (incrementing the sum), each `TimesGroup` passes it through unchanged, and `ProductSeed<Q>` starts with `PlusZero<Q.Total>`. The result: `DistrSum` witnesses `a*b + a*c = a*(b+c)`.

### Multiplicative identity: `n * 1 = n` and `1 * n = n`

`MulRightOne` proves `n * 1 = n` for all n. The base case is `TimesGroup<TimesZero<Zero>>` (one group of zero ticks); the inductive step uses `SuccLeftMul.Distributed` to add one tick to the single group. `MulLeftOne` proves `1 * n = n` by direct construction: one tick per group, n groups.

### Algebraic identities via distributivity

Distributivity combines with SuccLeftMul and MulRightOne to prove algebraic identities that explain *why* numerical correspondences hold, not just *that* they hold:

**Difference of squares:** `n*(n+2) + 1 = (n+1)^2`. Both sides decompose via a shared base `n*(n+1)`: SuccLeftMul gives `(n+1)^2 = n*(n+1) + (n+1)`, and distributivity gives `n*(n+2) = n*(n+1) + n`. The remainders differ by exactly 1. This algebraically explains the Wallis product factor correspondence `(2k-1)(2k+1) + 1 = (2k)^2`.

**Cassini identity:** `F(n-1)*F(n+1) - F(n)^2 = (-1)^n`. The key step uses distributivity: `F(n+1)*F(n-1) = (F(n) + F(n-1)) * F(n-1) = F(n)*F(n-1) + F(n-1)^2`. This is the first number-theoretic theorem in the project -- a statement about Fibonacci *structure*, not just Fibonacci *computation*.

**CF convergent determinant identity:** `h_n*k_{n-1} - h_{n-1}*k_n = (-1)^{n+1}`. This structural invariant holds for all continued fractions. For the golden ratio it reduces to Cassini (since h_n = F(n+2), k_n = F(n+1)). Demonstrated for sqrt(2) at n=1,2: products are built using the universal theorems `MulLeftOne` and `SuccLeftMul.Distributed` -- the same theorems the proof macros now reference instead of generating brute-force chains.

## Coinductive streams for irrational numbers

The convergent proofs above are bounded-depth: macros generate witness chains for specific values. Coinductive streams provide a complementary representation: the continued fraction coefficient sequence *itself* as a type.

A `CFStream` has a `Head` (the current coefficient) and a `Tail` (the rest of the stream). For periodic continued fractions, self-referential types create a productive fixed point -- Swift resolves these lazily, so chaining `.Tail.Tail...Head` always terminates:

```swift
// Golden ratio phi = [1; 1, 1, 1, ...]
struct PhiCF: CFStream {
    typealias Head = N1
    typealias Tail = PhiCF  // self-referential fixed point
}

// sqrt(2) = [1; 2, 2, 2, ...]
struct Sqrt2CF: CFStream {
    typealias Head = N1
    typealias Tail = Sqrt2Periodic  // enters the periodic part
}
```

Coefficient extraction works at any depth:

```swift
assertEqual(PhiCF.Head.self, N1.self)               // a_0 = 1
assertEqual(PhiCF.Tail.Tail.Tail.Head.self, N1.self) // a_3 = 1
assertStreamEqual(PhiCF.Tail.self, PhiCF.self)       // the fixed point
```

Universal unfold theorems prove that periodic streams unfold to themselves at *any* depth, not just specific ones. The proof uses the Seed-based induction pattern:

```swift
// PhiUnfold: for any n, the n-th Tail of PhiCF is PhiCF
assertStreamEqual(AddOne<AddOne<AddOne<PhiUnfoldSeed>>>.Unfolded.self, PhiCF.self)
```

**Limitation:** The streams encode the *identity* of an irrational number (its coefficient sequence), not the *computation* of convergents. The CF recurrence `h_{n+1} = a*h_n + h_{n-1}` requires adding two abstract naturals in one step, which Swift's conditional conformance cannot express. Convergent computation remains bounded-depth via macros.

## sqrt(2) CF and matrix construction

The sqrt(2) continued fraction [1; 2, 2, 2, ...] has convergents that can be computed either by the three-term recurrence (h_n = 2h_{n-1} + h_{n-2}) or by iterated left-multiplication by the matrix [[2,1],[1,0]]. The `@Sqrt2ConvergenceProof(depth:)` macro constructs both representations and proves they agree:

```swift
@Sqrt2ConvergenceProof(depth: 3)
enum Sqrt2Proof {}

assertEqual(Sqrt2Proof._MAT3.A.self, Sqrt2Proof._CF3.P.self)  // 17 = 17
assertEqual(Sqrt2Proof._MAT3.B.self, Sqrt2Proof._CF3.Q.self)  // 12 = 12
```

## Building

```sh
swift build                      # compile (compilation = proof)
swift run AbuseOfNotationClient  # exits cleanly
swift test                       # run macro expansion tests
```
