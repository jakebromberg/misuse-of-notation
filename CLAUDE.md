# Project overview

A Swift project exploring the boundary of what can be proved at compile time using only the type system. It started with Peano-encoded natural numbers but has grown into a proof assistant where compilation is verification. Witness types encode arithmetic relationships, coinductive streams encode infinite objects, and macros perform unbounded proof search while the type checker verifies correctness. The interesting question is always: what *else* can this encode?

## Project structure

```
Package.swift                                -- SPM package definition
Sources/
  AbuseOfNotation/                           -- library: types, witnesses, type-level arithmetic
    PeanoTypes.swift                         -- protocols (Integer, Natural, Nonpositive), Zero, AddOne, SubOne, assertEqual
    Witnesses.swift                          -- witness protocols and constructors (NaturalSum, NaturalProduct, NaturalLessThan)
    TypeLevelArithmetic.swift                -- NaturalExpression, type aliases (N0-N105), Sum, Product, _TimesNk protocols
    CayleyDickson.swift                      -- Cayley-Dickson construction (Algebra marker protocol, CayleyDickson type)
    ContinuedFractions.swift                 -- Fraction, GCFConvergent (CF convergents), LeibnizPartialSum (Leibniz series), WallisPartialProduct (Wallis product), Matrix2x2, Mat2, Sqrt2MatStep (matrix construction)
    Fibonacci.swift                          -- FibState, FibVerified, Fib0, FibStep (Fibonacci recurrence witnesses)
    AdditionTheorems.swift                   -- universal addition theorems (AddLeftZero, SuccLeftAdd, AddCommutative, AddAssociative via ProofSeed)
    MultiplicationTheorems.swift             -- flat multiplication witnesses (TimesTick, TimesGroup), universal theorems (MulLeftZero, SuccLeftMul, MulComm)
    DistributivityTheorem.swift              -- distributivity of multiplication over addition (ProductSeed, MulDistributive)
    Streams.swift                            -- CFStream protocol, periodic irrationals (PhiCF, Sqrt2CF), unfold theorems, assertStreamEqual
    Macros.swift                             -- macro declarations (@ProductConformance, @FibonacciProof, @PiConvergenceProof, @GoldenRatioProof, @Sqrt2ConvergenceProof, @MulCommProof, @WallisProductProof)
  AbuseOfNotationMacros/                     -- .macro target: compiler plugin
    Plugin.swift                             -- CompilerPlugin entry point
    ProductConformanceMacro.swift            -- @ProductConformance(n) (peer macro for inductive multiplication)
    FibonacciProofMacro.swift                -- @FibonacciProof(upTo:) (member macro generating Fibonacci witness chains)
    PiConvergenceProofMacro.swift            -- @PiConvergenceProof(depth:) (member macro generating Brouncker-Leibniz proof)
    GoldenRatioProofMacro.swift              -- @GoldenRatioProof(depth:) (member macro generating golden ratio CF/Fibonacci proof)
    Sqrt2ConvergenceProofMacro.swift         -- @Sqrt2ConvergenceProof(depth:) (member macro generating sqrt(2) CF/matrix proof)
    MulCommProofMacro.swift                  -- @MulCommProof(leftOperand:depth:) (member macro generating paired commutativity proofs)
    WallisProductProofMacro.swift            -- @WallisProductProof(depth:) (member macro generating Wallis product proof)
    ProductChainGenerator.swift              -- shared product witness chain generator (used by Pi, Wallis macros; universal factor optimization for factors 1 and 2)
    Diagnostics.swift                        -- PeanoDiagnostic enum
  AbuseOfNotationClient/                     -- SPM executable: witness-based proofs
    main.swift                               -- witness constructions verified by compilation, type-level arithmetic assertions
    Experiment.swift                         -- Seed<A>, _InductiveAdd, _Rebase experiments
Tests/
  AbuseOfNotationMacrosTests/                -- macro expansion tests
    ProductConformanceMacroTests.swift
    FibonacciProofMacroTests.swift
    PiConvergenceProofMacroTests.swift
    GoldenRatioProofMacroTests.swift
    Sqrt2ConvergenceProofMacroTests.swift
    MulCommProofMacroTests.swift
    WallisProductProofMacroTests.swift
```

## Building and testing

```sh
swift build                      # compile (compilation = proof)
swift run AbuseOfNotationClient  # exits cleanly (no runtime computation)
swift test                       # run macro expansion tests
```

### Testing conventions

- Arithmetic correctness is verified by witness construction: if the types compile, the proof is valid.
- `assertEqual<T: Integer>(_: T.Type, _: T.Type)` asserts type equality at compile time (empty body -- compilation is the assertion). `assertStreamEqual<T: CFStream>` does the same for stream types.
- Macro expansion correctness is verified by `assertMacroExpansion` in `swift test`.
- A clean `swift build && swift run AbuseOfNotationClient && swift test` means all checks pass.

## Code conventions

- Integers are represented as types (`Zero`, `AddOne<N>`, `SubOne<N>`) conforming to protocols in the `Integer` hierarchy.
- The protocol hierarchy has 3 protocols: `Integer` (root) -> `Natural` and `Nonpositive`. `Zero` conforms to both `Natural` and `Nonpositive`.
- Type aliases `N0` through `N9` provide convenient shorthand for small naturals.
- Witness protocols (`NaturalSum`, `NaturalProduct`, `NaturalLessThan`) encode arithmetic relationships as associated type constraints.
- Witness constructors follow Peano axioms: base case (e.g. `PlusZero<N>` for `N + 0 = N`) and inductive step (e.g. `PlusSucc<Proof>` for `A + S(B) = S(C)` given `A + B = C`).
- `TimesSucc` composes a product witness with a sum witness via `where` constraints, encoding `a * S(b) = a*b + a`.
- Type-level `Sum` and `Product` use constrained extensions for small left operands.
- The `@ProductConformance(n)` macro generates inductive protocols and conformances for `Product`.
- The `@FibonacciProof(upTo:)` macro generates Fibonacci witness chains as members of the attached type.
- The `@PiConvergenceProof(depth:)` macro generates the Brouncker-Leibniz correspondence proof as members, including CF convergents, Leibniz partial sums, product/sum witnesses, and type equality assertions.
- The `@GoldenRatioProof(depth:)` macro generates the golden ratio CF / Fibonacci correspondence proof, showing that CF [1;1,1,...] convergents h_n/k_n equal F(n+2)/F(n+1).
- The `@Sqrt2ConvergenceProof(depth:)` macro generates the sqrt(2) CF / matrix correspondence proof, showing that CF [1;2,2,...] convergents match iterated left-multiplication by [[2,1],[1,0]] via Sqrt2MatStep.
- The `@WallisProductProof(depth:)` macro generates the Wallis product proof: unreduced partial products W_k, two-step product decomposition (multiplying by 2k twice instead of (2k)^2 once), and a factor correspondence proving (2k-1)(2k+1) + 1 = (2k)^2 at each step. Practical depth limit is 2 (products grow fast -- depth 3 exceeds macro output limits).
- Proof-generating macros use `@attached(member, names: arbitrary)` to scope generated types inside a namespace enum (e.g., `FibProof._Fib1`, `PiProof._CF1`).
- The macro is the proof SEARCH (arbitrary integer computation at compile time); the type checker is the proof VERIFIER (structural constraint verification).
- Universal theorems use conditional conformance as structural induction: a base case on `Zero`/`PlusZero` and an inductive step on `AddOne`/`PlusSucc`. Protocols use plain associated types (no `where` clauses) following the `_TimesNk` pattern to avoid rewrite system limits; correctness is enforced structurally by the conformance definitions.
- `AddLeftZero` proves `0 + n = n` for all n. `SuccLeftAdd` proves `a + b = c => S(a) + b = S(c)` for all proofs. `AddCommutative` proves `a + b = c => b + a = c` for all proofs (combines the first two).
- `ProofSeed<P>` is a `Natural`-conforming enum that wraps a `NaturalSum` proof as a base case for inductive proof extension. Analogous to `Seed<A>` but wraps a proof instead of a number.
- `AddAssociative` proves associativity: given P witnessing `a + b = d`, `AddOne^c(ProofSeed<P>).AssocProof = PlusSucc^c(P)` witnesses `a + (b + c) = d + c`. Universality is parametric over P and inductive over c.
- The flat multiplication encoding (`TimesTick`/`TimesGroup`) decomposes each multiplication step into individual successor operations, like `PlusSucc` does for addition. This avoids `TimesSucc`'s where clauses, which trigger rewrite system explosion when composed in inductive protocols. The two encodings coexist -- both conform to `NaturalProduct`. `TimesSucc` is used by macro-generated proofs for factors >= 3; factors 1 and 2 reference the universal theorems `MulLeftOne` and `SuccLeftMul.Distributed` directly, eliminating product chains entirely from the golden ratio and sqrt(2) macros and reducing them in the pi and Wallis macros.
- `TimesTick<P>` adds 1 to Total (one successor within a "copy of Left"). No where clauses. `TimesGroup<P>` adds 1 to Right (one complete copy of Left added). No where clauses. For `a * b`, the proof has b groups of a ticks each.
- `MulLeftZero` proves `0 * n = 0` for all n. `ZeroTimesProof: NaturalProduct & SuccLeftMul` -- the strengthened constraint enables chaining into commutativity proofs. With Left = 0, each group has 0 ticks, so the inductive step is just `TimesGroup` wrapping the previous proof.
- `SuccLeftMul` proves `a * b = c => S(a) * b = c + b` for all flat multiplication proofs. `Distributed: NaturalProduct & SuccLeftMul` -- the strengthened self-referential constraint ensures the output is itself distributable, enabling inductive chaining. Each `TimesGroup` gains one extra `TimesTick` (the new successor contributes one extra unit per copy), so b groups contribute b extra ticks. Structurally identical to how `SuccLeftAdd` wraps each `PlusSucc`.
- `_MulCommN2` / `_MulCommN3` prove `Nk * b = b * Nk` for all b (per-A commutativity). Each protocol carries paired proofs: `FwdProof` (A * b, hardcoded A ticks per group) and `RevProof` (b * A, chained via `SuccLeftMul.Distributed`). Seed types (`_MulCommN2Seed`, `_MulCommN3Seed`) provide the base case (b = 0). Per-A universality follows the `_TimesNk` pattern. Full universality over both a and b simultaneously hasn't been achieved yet, but the techniques are still evolving.
- The `@MulCommProof(leftOperand: A, depth: D)` macro generates bounded-depth paired commutativity proofs as members of a namespace enum. For each b from 0 to D, `_FwdK` witnesses `A * b` (flat encoding: A ticks per group) and `_RevK` witnesses `b * A` (via `SuccLeftMul.Distributed`). The type checker verifies that both Totals match. This complements the universal per-A protocols: the manual protocols prove commutativity for all b, while the macro proves it for specific b values up to the given depth for any A >= 2.
- `MulRightOne` proves `n * 1 = n` for all n. Base case: `TimesGroup<TimesZero<Zero>>` (one group of zero ticks). Inductive step uses `SuccLeftMul.Distributed` (adds one tick to the single group). `MulLeftOne` proves `1 * n = n` by direct construction: one tick per group, n groups.
- `ProductSeed<Q>` is a `NaturalProduct`-conforming enum that wraps an existing product proof Q as a base case for distributivity proof extension. Analogous to `ProofSeed<P>` for addition associativity, but wraps a product proof instead of a sum proof. Building c groups of Left ticks on `ProductSeed<Q>` constructs the a*c portion while Q provides the a*b portion.
- `MulDistributive` tracks a `NaturalSum` witness (`DistrSum`) through a product proof, proving distributivity: `a * (b + c) = a*b + a*c`. Each `TimesTick` wraps `DistrSum` in `PlusSucc` (adding 1 to the sum), each `TimesGroup` passes `DistrSum` through unchanged, and `ProductSeed<Q>` starts with `PlusZero<Q.Total>`. The result: `DistrSum` witnesses `a*b + a*c = a*(b+c)`.
- The difference-of-squares identity `n*(n+2) + 1 = (n+1)^2` is demonstrated at specific n using shared-base decomposition: both sides decompose via `n*(n+1)`, with `(n+1)^2 = n*(n+1) + (n+1)` (SuccLeftMul) and `n*(n+2) = n*(n+1) + n` (distributivity + MulRightOne). Remainders differ by 1. This algebraically explains the Wallis product factor correspondence.
- The Cassini identity `F(n-1)*F(n+1) - F(n)^2 = (-1)^n` is demonstrated at n=2,3,4 using distributivity to decompose `F(n+1)*F(n-1) = (F(n)+F(n-1))*F(n-1) = F(n)*F(n-1) + F(n-1)^2`.
- The CF convergent determinant identity `h_n*k_{n-1} - h_{n-1}*k_n = (-1)^{n+1}` is demonstrated for sqrt(2) at n=1,2. Products are constructed using `MulLeftOne` and chained `SuccLeftMul.Distributed` (the same universal theorems the macros now reference). For the golden ratio, this identity reduces to Cassini. The identity connects the CF convergent matrix representation to number-theoretic structure.
- The Wallis-Leibniz denominator correspondence `WQ[k] = LQ[k+1] * LQ[k]` connects the Wallis product to the Leibniz series: each Wallis denominator is the product of two consecutive Leibniz denominators. Demonstrated at k=1 (3 = 3*1 via `MulRightOne`) and k=2 (45 = 15*3 via chained `SuccLeftMul.Distributed`). Since the Brouncker-Leibniz correspondence gives `CF_k.P = LS_{k+1}.Q`, this also yields `WQ[k] = CF_k.P * CF_{k-1}.P`, completing a three-way connection between all pi representations. A bonus exact fraction `W_1 = 2*S_2` (4/3 = 2*(2/3)) is also proved.
- `CFStream` is a coinductive stream protocol with `Head: Natural` and `Tail: CFStream`. For periodic continued fractions, self-referential types create productive fixed points (e.g., `PhiCF.Tail = PhiCF`). Swift resolves these lazily -- `.Tail.Tail...Head` always terminates.
- `PhiCF` represents the golden ratio CF [1; 1, 1, ...] (entirely periodic, self-referential). `Sqrt2Periodic` represents [2; 2, 2, ...] (periodic tail). `Sqrt2CF` represents sqrt(2) = [1; 2, 2, ...] (transient head + periodic tail).
- `PhiUnfold` / `Sqrt2PeriodicUnfold` prove that periodic streams unfold to themselves at any depth, using the Seed-based induction pattern. `PhiUnfoldSeed` / `Sqrt2PeriodicUnfoldSeed` provide the base case (depth 0); `AddOne` applies `.Tail` for the inductive step.
- `assertStreamEqual<T: CFStream>(_: T.Type, _: T.Type)` provides compile-time type equality assertions for `CFStream` types, analogous to `assertEqual` for `Integer` types.
- Universal convergent extraction from streams hasn't been achieved yet. The CF recurrence `h_{n+1} = a*h_n + h_{n-1}` seems to require adding two abstract naturals in one step, which conditional conformance alone can't express. But the Seed/ProductSeed technique of wrapping one structure and inducting over another might offer a path. For now, convergent computation remains bounded-depth via macros. The streams encode the *identity* of the irrational number (its coefficient sequence); connecting identity to computation is an open problem.

## Proof techniques

Recurring patterns that have enabled theorems previously thought impossible. These are the transferable ideas -- when facing a new theorem, check whether one of these applies before concluding it can't be done.

- **Flat decomposition.** When a composite operation (like TimesSucc) requires where clauses that explode in inductive contexts, decompose it into where-clause-free primitives (TimesTick/TimesGroup). The type checker handles primitives one step at a time without needing to solve the composed constraint. This turned multiplication from a macro-only operation into something universal theorems could reason about.
- **Seed wrapping.** To do induction over two parameters when conditional conformance only supports one: wrap the first parameter's proof inside a Natural-conforming seed type, then do induction over the second parameter using AddOne layers on top. ProofSeed wraps a NaturalSum, ProductSeed wraps a NaturalProduct. The pattern is general -- any protocol-conforming value can be wrapped.
- **Witness composition.** One witness can live inside another witness's structure. MulDistributive puts a NaturalSum (DistrSum) inside a NaturalProduct proof, tracking the additive relationship that emerges from the multiplicative structure. This is how distributivity bridges the two witness systems. The technique isn't limited to sum-inside-product.
- **Strengthened self-referential constraints.** Requiring that an associated type conform to the same protocol as the parent (e.g., `Distributed: NaturalProduct & SuccLeftMul`) ensures outputs are themselves inputs to further induction. This is what makes SuccLeftMul chain universally. Any protocol that needs to compose inductively should consider this pattern.
- **Coinductive fixed points.** Self-referential type definitions (PhiCF.Tail = PhiCF) create productive infinite structures that Swift resolves lazily. This goes beyond induction into coinduction -- encoding infinite objects rather than finite proofs.

## Open questions

Things that might be possible but haven't been tried or fully explored. Previous "impossible" results have fallen to new techniques, so treat these as open, not closed.

- **Multiplicative associativity.** Can ProductSeed (or a nested variant) prove `(a * b) * c = a * (b * c)`? The flat encoding decomposes both sides into ticks and groups; the question is whether one decomposition can be structurally transformed into the other.
- **Nested seeds.** ProofSeed wraps a proof to induct over a second parameter. Can you wrap a seed in another seed to induct over a third? This could unlock theorems involving three or more variables.
- **Witness-tracking generalization.** Distributivity tracked a NaturalSum inside a NaturalProduct. What about tracking a NaturalProduct inside a NaturalProduct (for associativity), or a NaturalLessThan through an arithmetic proof (for order-preserving properties)?
- **Universal two-variable multiplication commutativity.** Per-A commutativity works. Can the Seed pattern, witness composition, or some other technique achieve `a * b = b * a` universally over both a and b?
- **Stream-convergent connection.** Connecting coinductive stream identity to bounded convergent computation. The CF recurrence needs two abstract additions in one step -- could witness composition provide a workaround?
- **Exponentiation.** NaturalPower witnesses for `a^b`, likely built on iterated multiplication. What proof techniques carry over from addition/multiplication?
- **Proof transport.** Given a proof of `a + b = c` and a proof of `c = d`, can you produce a proof of `a + b = d`? Equality witnesses could enable rewriting across proof systems.

## Branching

- `master` -- witness-based proofs, type-level arithmetic, structural type definitions.
- `witness-based-proofs` -- PR 1: paradigm shift from runtime computation to witness-based proofs.
- `macro-cleanup` -- PR 2: removes computational macros, Xcode target, updates docs.
- `continued-fractions` -- PR 3: golden ratio CF/Fibonacci and sqrt(2) CF/matrix correspondence proofs.
- `addition-associativity` -- PR for issue #29: associativity of addition via ProofSeed.
- `multiplication-theorems` -- PR for issue #30: universal multiplication theorems (MulLeftZero, SuccLeftMul via flat encoding).
- `coinductive-streams` -- PR for issue #31: coinductive CF streams for irrational numbers (PhiCF, Sqrt2CF, unfold theorems).
- `mul-comm-macro` -- PR for issue #32: @MulCommProof macro for automated commutativity proof generation.
- `distributivity` -- PR for distributivity of multiplication over addition (ProductSeed, MulDistributive).
