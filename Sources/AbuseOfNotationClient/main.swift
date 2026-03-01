import AbuseOfNotation

// ============================================================================
// Abuse of Notation: A tutorial
//
// This file is a guided tour through encoding natural numbers as Swift types.
// Every statement below is verified by the compiler -- if this file compiles,
// every theorem here is correct. There is no runtime computation; the program
// exits immediately. The proof is the compilation itself.
// ============================================================================

// MARK: - 1. Peano types

// The natural numbers are built from two primitives:
//   Zero       -- the number 0
//   AddOne<N>  -- the successor of N (i.e. N + 1)
//
// Every natural number is a unique nesting of AddOne around Zero:
//   0 = Zero
//   1 = AddOne<Zero>
//   2 = AddOne<AddOne<Zero>>
//   3 = AddOne<AddOne<AddOne<Zero>>>
//
// Type aliases N0 through N9 provide shorthand:

assertEqual(N0.self, Zero.self)
assertEqual(N1.self, AddOne<Zero>.self)
assertEqual(N2.self, AddOne<AddOne<Zero>>.self)
assertEqual(N3.self, AddOne<AddOne<AddOne<Zero>>>.self)

// assertEqual is a function with an empty body. Its signature requires both
// arguments to have the same type:
//
//   func assertEqual<T: Integer>(_: T.Type, _: T.Type) {}
//
// If the two types differ, the compiler rejects the call. If they match,
// it compiles -- and that successful compilation IS the assertion.

// MARK: - 2. Addition witnesses

// A witness is a type whose existence proves a mathematical fact. The
// NaturalSum protocol witnesses that Left + Right = Total.
//
// Two constructors encode the Peano axioms for addition:
//   PlusZero<N>    -- proves N + 0 = N                     (base case)
//   PlusSucc<P>    -- if P proves A + B = C,               (inductive step)
//                     proves A + S(B) = S(C)

// Theorem: 0 + 0 = 0
assertEqual(PlusZero<N0>.Total.self, N0.self)

// Theorem: 3 + 0 = 3
assertEqual(PlusZero<N3>.Total.self, N3.self)

// Theorem: 2 + 1 = 3
// Start with 2 + 0 = 2 (PlusZero), then peel one successor onto the right:
//   2 + 0 = 2  =>  2 + S(0) = S(2)  =>  2 + 1 = 3
typealias TwoPlusOne = PlusSucc<PlusZero<N2>>
assertEqual(TwoPlusOne.Total.self, N3.self)

// Theorem: 2 + 3 = 5
// Each PlusSucc moves a successor from the right operand to the total:
//   2 + 0 = 2  =>  2 + 1 = 3  =>  2 + 2 = 4  =>  2 + 3 = 5
typealias TwoPlusThree = PlusSucc<PlusSucc<PlusSucc<PlusZero<N2>>>>
assertEqual(TwoPlusThree.Total.self, N5.self)

// Theorem: 3 + 2 = 5  (commutativity instance)
// A different proof arriving at the same Total:
typealias ThreePlusTwo = PlusSucc<PlusSucc<PlusZero<N3>>>
assertEqual(ThreePlusTwo.Total.self, N5.self)

// Both witnesses prove different facts (2+3=5 vs 3+2=5) but their Totals
// agree -- we can assert this directly:
assertEqual(TwoPlusThree.Total.self, ThreePlusTwo.Total.self)

// MARK: - 3. Multiplication witnesses

// Multiplication extends addition. The NaturalProduct protocol witnesses
// that Left * Right = Total, using two constructors:
//   TimesZero<N>            -- proves N * 0 = 0             (base case)
//   TimesSucc<Mul, Add>     -- if Mul proves A * B = C      (inductive step)
//                              and Add proves C + A = D,
//                              then A * S(B) = D
//
// The inductive step encodes the Peano axiom: a * S(b) = a*b + a.
// Each step requires BOTH a multiplication witness AND a sum witness.

// Theorem: 2 * 0 = 0
assertEqual(TimesZero<N2>.Total.self, N0.self)

// Theorem: 2 * 1 = 2
// Step 1: 2 * 0 = 0 (base)
// Step 2: 0 + 2 = 2 (sum witness), so 2 * S(0) = 2, i.e. 2 * 1 = 2
typealias Mul2x0 = TimesZero<N2>
typealias Add0p2 = PlusSucc<PlusSucc<PlusZero<N0>>>
typealias Mul2x1 = TimesSucc<Mul2x0, Add0p2>
assertEqual(Mul2x1.Total.self, N2.self)

// Theorem: 2 * 2 = 4
// 2 * 1 = 2 (from above), and 2 + 2 = 4, so 2 * 2 = 4
typealias Add2p2 = PlusSucc<PlusSucc<PlusZero<N2>>>
typealias Mul2x2 = TimesSucc<Mul2x1, Add2p2>
assertEqual(Mul2x2.Total.self, N4.self)

// Theorem: 2 * 3 = 6
// 2 * 2 = 4 (from above), and 4 + 2 = 6, so 2 * 3 = 6
typealias Add4p2 = PlusSucc<PlusSucc<PlusZero<N4>>>
typealias Mul2x3 = TimesSucc<Mul2x2, Add4p2>
assertEqual(Mul2x3.Total.self, N6.self)

// Each multiplication proof is a chain of TimesSucc steps, each composing
// the previous product with a new sum. The structure mirrors how you'd
// prove 2*3 = 6 by hand using the Peano axioms.

// MARK: - 4. Comparison witnesses

// The NaturalLessThan protocol witnesses that Left < Right:
//   ZeroLT<N>      -- proves 0 < S(N)                      (base case)
//   SuccLT<P>      -- if P proves A < B,                    (inductive step)
//                     proves S(A) < S(B)

// Theorem: 0 < 1
// Direct from the base case: 0 < S(0).
typealias ZeroLtOne = ZeroLT<N0>

// Theorem: 0 < 3
// Also direct: 0 < S(S(S(0))), i.e. 0 < S(N2).
typealias ZeroLtThree = ZeroLT<N2>

// Theorem: 2 < 5
// Peel off successors from both sides until the left reaches zero:
//   0 < 3  =>  S(0) < S(3)  =>  S(S(0)) < S(S(3))  =>  2 < 5
typealias TwoLtFive = SuccLT<SuccLT<ZeroLT<N2>>>

// MARK: - 5. Type-level arithmetic

// Writing witness chains by hand is explicit but verbose. Type-level
// arithmetic provides a more concise notation:
//
//   Sum<L, R>.Result     -- the type representing L + R
//   Product<L, R>.Result -- the type representing L * R
//
// These use constrained extensions to compute at the type level.
// The compiler resolves the Result associated type during compilation.

// Addition:
assertEqual(Sum<N0, N5>.Result.self, N5.self)
assertEqual(Sum<N1, N2>.Result.self, N3.self)
assertEqual(Sum<N2, N3>.Result.self, N5.self)
assertEqual(Sum<N3, N3>.Result.self, N6.self)

// Multiplication:
assertEqual(Product<N0, N7>.Result.self, N0.self)
assertEqual(Product<N1, N5>.Result.self, N5.self)
assertEqual(Product<N2, N3>.Result.self, N6.self)
assertEqual(Product<N3, N3>.Result.self, N9.self)

// Commutativity:
assertEqual(Product<N2, N3>.Result.self, Product<N3, N2>.Result.self)

// MARK: - 6. Inductive multiplication (conditional conformance as induction)

// How does Product<N2, R> work for ANY R, not just specific values?
// The answer is conditional conformance -- Swift's mechanism for structural
// induction.
//
// The _TimesN2 protocol defines a type-level function via two conformances:
//
//   extension Zero: _TimesN2 {
//       typealias _TimesN2Result = Zero              // base: 2 * 0 = 0
//   }
//   extension AddOne: _TimesN2 where Predecessor: _TimesN2 {
//       typealias _TimesN2Result = AddOne<AddOne<Predecessor._TimesN2Result>>
//   }                                                // step: 2 * S(n) = S(S(2*n))
//
// This is a proof by induction: Zero is the base case, and the AddOne
// conformance is the inductive step. For any concrete natural N, the
// compiler chains from AddOne down to Zero, resolving the result.
//
// The @ProductConformance macro generates these conformances automatically.
// Product<N2, R> and Product<N3, R> both work for any R thanks to this.

assertEqual(Product<N2, N4>.Result.self, N8.self)
assertEqual(Product<N3, N2>.Result.self, N6.self)

// MARK: - 7. Cayley-Dickson construction: higher-dimensional algebras

// The Cayley-Dickson construction builds algebras by pairing elements.
// Starting from integers (level 0), each level doubles the dimension:
//
//   Level 0: Integers          -- 1-dimensional scalars
//   Level 1: Gaussian integers -- 2D (a + bi), like complex numbers over Z
//   Level 2: Quaternions       -- 4D (a + bi + cj + dk)
//   Level 3: Octonions         -- 8D
//
// The Algebra marker protocol tags types that participate in this hierarchy.
// Integer types (Zero, AddOne, SubOne) conform as level-0 scalars.
// CayleyDickson<Re, Im> pairs two Algebra types to form the next level.

// A Gaussian integer: 3 + 2i
typealias ThreePlus2i = CayleyDickson<N3, N2>

// Another: 1 + 0i (a real integer embedded in the Gaussian integers)
typealias OnePlus0i = CayleyDickson<N1, N0>

// A quaternion: (1 + 2i) + (3 + 4i)j, represented as a pair of pairs.
// This is the quaternion 1 + 2i + 3j + 4k.
typealias Quat1234 = CayleyDickson<CayleyDickson<N1, N2>, CayleyDickson<N3, N4>>

// The construction is purely structural at the type level -- it encodes
// the algebraic *shape* (which components exist and how they nest) without
// computing operations like multiplication or conjugation. This reflects
// the project's philosophy: the type system encodes structure and proves
// relationships; it doesn't compute values.

// MARK: - 8. Negative integers and the full hierarchy

// The Integer protocol sits at the root, with Natural and Nonpositive
// as refinements. SubOne<N> mirrors AddOne<N> on the nonpositive side:
//
//   ... SubOne<SubOne<Zero>> = -2
//       SubOne<Zero>         = -1
//       Zero                 =  0
//       AddOne<Zero>         =  1
//       AddOne<AddOne<Zero>> =  2 ...
//
// Zero conforms to BOTH Natural and Nonpositive -- it's the unique element
// at the intersection, just as 0 is both nonneg and nonpos.

typealias Neg1 = SubOne<Zero>
typealias Neg2 = SubOne<Neg1>

// The Successor/Predecessor associated types thread through the hierarchy:
assertEqual(Zero.Successor.self, N1.self)
assertEqual(N1.Successor.self, N2.self)
assertEqual(Zero.Predecessor.self, Neg1.self)

// MARK: - 9. Continued fractions and pi (macro-generated proof)

// Two classical formulas approximate pi from opposite directions:
//
//   Brouncker's continued fraction for 4/pi:
//     4/pi = 1 + 1^2/(2 + 3^2/(2 + 5^2/(2 + 7^2/(2 + ...))))
//
//   Leibniz series for pi/4:
//     pi/4 = 1 - 1/3 + 1/5 - 1/7 + ...
//
// At every depth n, the CF convergent h_n/k_n equals 1/S_{n+1}, where
// S_{n+1} is the (n+1)-th Leibniz partial sum. Proving this correspondence
// at the type level demonstrates that both representations converge to the
// same value: pi.
//
// The #piConvergenceProof macro computes everything at compile time:
//   1. CF convergents h_i/k_i via the standard recurrence
//   2. Leibniz partial sums S_k as fractions
//   3. All NaturalProduct and NaturalSum witness chains
//   4. Type equality assertions proving the correspondence
//
// The macro is the proof SEARCH (arbitrary integer computation). The type
// checker is the proof VERIFIER (structural constraint verification). If
// any witness chain is wrong, compilation fails -- the macro cannot lie.

@PiConvergenceProof(depth: 3)
enum PiProof {}

// The macro generated CF convergents _CF0..._CF3 and Leibniz partial sums
// _LS1..._LS4, plus all intermediate multiplication and addition witnesses,
// as members of PiProof. Verify the computed values:

assertEqual(PiProof._CF0.P.self, N1.self)    // h_0 = 1
assertEqual(PiProof._CF0.Q.self, N1.self)    // k_0 = 1
assertEqual(PiProof._CF1.P.self, N3.self)    // h_1 = 3
assertEqual(PiProof._CF1.Q.self, N2.self)    // k_1 = 2
assertEqual(PiProof._CF2.P.self, N15.self)   // h_2 = 15
assertEqual(PiProof._CF2.Q.self, N13.self)   // k_2 = 13
assertEqual(PiProof._CF3.P.self, N105.self)  // h_3 = 105
assertEqual(PiProof._CF3.Q.self, N76.self)   // k_3 = 76

assertEqual(PiProof._LS1.P.self, N1.self)    // S_1 = 1/1
assertEqual(PiProof._LS1.Q.self, N1.self)
assertEqual(PiProof._LS2.P.self, N2.self)    // S_2 = 2/3
assertEqual(PiProof._LS2.Q.self, N3.self)
assertEqual(PiProof._LS3.P.self, N13.self)   // S_3 = 13/15
assertEqual(PiProof._LS3.Q.self, N15.self)
assertEqual(PiProof._LS4.P.self, N76.self)   // S_4 = 76/105
assertEqual(PiProof._LS4.Q.self, N105.self)

// The macro also generated _piCorrespondenceCheck(), a function whose
// compilation verifies the Brouncker-Leibniz correspondence at each depth:
//   assertEqual(_CF1.P, _LS2.Q)  -- h_1 = S_2 denominator (3 = 3)
//   assertEqual(_CF1.Q, _LS2.P)  -- k_1 = S_2 numerator   (2 = 2)
//   assertEqual(_CF2.P, _LS3.Q)  -- h_2 = S_3 denominator (15 = 15)
//   assertEqual(_CF2.Q, _LS3.P)  -- k_2 = S_3 numerator   (13 = 13)
//   assertEqual(_CF3.P, _LS4.Q)  -- h_3 = S_4 denominator (105 = 105)
//   assertEqual(_CF3.Q, _LS4.P)  -- k_3 = S_4 numerator   (76 = 76)
//
// These type equalities prove that Brouncker's CF for 4/pi and the Leibniz
// series for pi/4 produce reciprocal rational approximations at each depth.
// Since both sequences converge, and their values agree, they converge to
// the same limit: pi.

// MARK: - 10. Wallis product (macro-generated proof)

// The Wallis product for pi/2:
//   pi/2 = prod_{k=1}^{inf} (2k)^2 / ((2k-1)(2k+1))
//
// Unreduced partial products: W_0 = 1/1, W_1 = 4/3, W_2 = 64/45, ...
//
// Each step multiplies the numerator by (2k)^2 and the denominator by
// (2k-1)(2k+1). The structural fingerprint: the numerator factor exceeds
// the denominator factor by exactly 1 at each step:
//   (2k)^2 = (2k-1)(2k+1) + 1
//
// This is provable at the type level: the macro emits a PlusSucc<PlusZero<...>>
// witness for each k. The factor correspondence is a difference-of-squares
// identity, verified by the type checker.
//
// Products grow fast, so the macro uses a two-step decomposition:
//   Numerator:   prev_p * 2k, then result * 2k
//   Denominator: prev_q * (2k-1), then result * (2k+1)

@WallisProductProof(depth: 2)
enum WallisProof {}

// Verify W_0 = 1/1:
assertEqual(WallisProof._W0.P.self, N1.self)
assertEqual(WallisProof._W0.Q.self, N1.self)

// Verify W_1 = 4/3:
assertEqual(WallisProof._W1.P.self, N4.self)
assertEqual(WallisProof._W1.Q.self, N3.self)

// MARK: - 11. Non-constant base case: Seed<A>

// The _TimesN2 pattern has a constant base case: Zero._TimesN2Result = Zero.
// By introducing Seed<A> — a parameterized type that conforms to Natural —
// we get a non-constant base case: Seed<A>._Sum = A.
// AddOne chains on top of Seed<A> then compute A + B via _InductiveAdd.

assertEqual(_Exp_5p0._Sum.self, N5.self)  // 5 + 0 = 5
assertEqual(_Exp_7p1._Sum.self, N8.self)  // 7 + 1 = 8
assertEqual(_Exp_3p2._Sum.self, N5.self)  // 3 + 2 = 5

// The base case is genuinely non-constant: different Seed<A> values
// produce different results through the same _InductiveAdd conformance.
assertEqual(Seed<N0>._Sum.self, N0.self)
assertEqual(Seed<N9>._Sum.self, N9.self)
assertEqual(AddOne<AddOne<AddOne<Seed<N4>>>>._Sum.self, N7.self)  // 4 + 3 = 7

// MARK: - 12. Fibonacci at the type level (macro-generated proof)

// The FibVerified protocol uses a where clause on its SumWitness
// associated type to force Next == Prev + Current. Each FibStep
// carries a NaturalSum witness proving the Fibonacci recurrence.
//
// Writing witness chains by hand is tedious -- the #fibonacciProof macro
// computes Fibonacci numbers as regular integers at compile time, then
// emits PlusSucc/PlusZero witness chains that the type checker verifies.

@FibonacciProof(upTo: 10)
enum FibProof {}

// The macro generated FibStep chains _Fib1 through _Fib10 as members
// of FibProof. Verify:
assertEqual(Fib0.Current.self, N0.self)            // F(0) = 0
assertEqual(Fib0.Next.self, N1.self)               // F(1) = 1
assertEqual(FibProof._Fib1.Current.self, N1.self)  // F(1) = 1
assertEqual(FibProof._Fib2.Current.self, N1.self)  // F(2) = 1
assertEqual(FibProof._Fib3.Current.self, N2.self)  // F(3) = 2
assertEqual(FibProof._Fib4.Current.self, N3.self)  // F(4) = 3
assertEqual(FibProof._Fib5.Current.self, N5.self)  // F(5) = 5
assertEqual(FibProof._Fib6.Current.self, N8.self)  // F(6) = 8

// MARK: - 13. Golden ratio and Fibonacci (macro-generated proof)

// The golden ratio phi = (1 + sqrt(5))/2 has the simplest continued fraction:
//   phi = [1; 1, 1, 1, ...]
//
// The CF recurrence with a=1, b=1 is just h_n = h_{n-1} + h_{n-2} -- the
// Fibonacci recurrence. The convergents h_n/k_n satisfy:
//   h_n = F(n+2),  k_n = F(n+1)
//
// The @GoldenRatioProof macro constructs both sequences independently:
//   1. FibStep witness chains proving F(i-1) + F(i) = F(i+1)
//   2. GCFConvStep convergents for the all-ones CF
// Then generates assertEqual calls verifying the correspondence.

@GoldenRatioProof(depth: 5)
enum GoldenRatioProof {}

// Verify CF convergents match Fibonacci values:
assertEqual(GoldenRatioProof._CF0.P.self, N1.self)   // h_0 = 1 = F(2)
assertEqual(GoldenRatioProof._CF0.Q.self, N1.self)   // k_0 = 1 = F(1)
assertEqual(GoldenRatioProof._CF1.P.self, N2.self)   // h_1 = 2 = F(3)
assertEqual(GoldenRatioProof._CF1.Q.self, N1.self)   // k_1 = 1 = F(2)
assertEqual(GoldenRatioProof._CF2.P.self, N3.self)   // h_2 = 3 = F(4)
assertEqual(GoldenRatioProof._CF2.Q.self, N2.self)   // k_2 = 2 = F(3)
assertEqual(GoldenRatioProof._CF3.P.self, N5.self)   // h_3 = 5 = F(5)
assertEqual(GoldenRatioProof._CF3.Q.self, N3.self)   // k_3 = 3 = F(4)
assertEqual(GoldenRatioProof._CF4.P.self, N8.self)   // h_4 = 8 = F(6)
assertEqual(GoldenRatioProof._CF4.Q.self, N5.self)   // k_4 = 5 = F(5)
assertEqual(GoldenRatioProof._CF5.P.self, N13.self)  // h_5 = 13 = F(7)
assertEqual(GoldenRatioProof._CF5.Q.self, N8.self)   // k_5 = 8 = F(6)

// MARK: - 14. sqrt(2) CF and matrix construction (macro-generated proof)

// The continued fraction for sqrt(2) is [1; 2, 2, 2, ...]:
//   sqrt(2) = 1 + 1/(2 + 1/(2 + 1/(2 + ...)))
//
// The CF recurrence with a=1, b=2 gives:
//   h_n = 2*h_{n-1} + h_{n-2},  k_n = 2*k_{n-1} + k_{n-2}
//
// Equivalently, left-multiplying by the matrix M = [[2,1],[1,0]]:
//   [[h_n, k_n], [h_{n-1}, k_{n-1}]] = M * [[h_{n-1}, k_{n-1}], [h_{n-2}, k_{n-2}]]
//
// The @Sqrt2ConvergenceProof macro constructs both representations:
//   1. CF convergents via GCFConvStep (three-term recurrence)
//   2. Matrix powers via Sqrt2MatStep (iterated left-multiplication)
// Then generates assertEqual calls proving they produce the same values.

@Sqrt2ConvergenceProof(depth: 3)
enum Sqrt2Proof {}

// Verify CF convergents:
assertEqual(Sqrt2Proof._CF0.P.self, N1.self)    // h_0 = 1
assertEqual(Sqrt2Proof._CF0.Q.self, N1.self)    // k_0 = 1
assertEqual(Sqrt2Proof._CF1.P.self, N3.self)    // h_1 = 3
assertEqual(Sqrt2Proof._CF1.Q.self, N2.self)    // k_1 = 2
assertEqual(Sqrt2Proof._CF2.P.self, N7.self)    // h_2 = 7
assertEqual(Sqrt2Proof._CF2.Q.self, N5.self)    // k_2 = 5
assertEqual(Sqrt2Proof._CF3.P.self, N17.self)   // h_3 = 17
assertEqual(Sqrt2Proof._CF3.Q.self, N12.self)   // k_3 = 12

// Verify matrix entries match:
assertEqual(Sqrt2Proof._MAT0.A.self, N1.self)   // MAT0 top-left = h_0 = 1
assertEqual(Sqrt2Proof._MAT0.B.self, N1.self)   // MAT0 top-right = k_0 = 1
assertEqual(Sqrt2Proof._MAT1.A.self, N3.self)   // MAT1 top-left = h_1 = 3
assertEqual(Sqrt2Proof._MAT1.B.self, N2.self)   // MAT1 top-right = k_1 = 2
assertEqual(Sqrt2Proof._MAT2.A.self, N7.self)   // MAT2 top-left = h_2 = 7
assertEqual(Sqrt2Proof._MAT2.B.self, N5.self)   // MAT2 top-right = k_2 = 5
assertEqual(Sqrt2Proof._MAT3.A.self, N17.self)  // MAT3 top-left = h_3 = 17
assertEqual(Sqrt2Proof._MAT3.B.self, N12.self)  // MAT3 top-right = k_3 = 12

// MARK: - 15. Universal addition theorems (structural induction)
//
// Unlike the proofs above (which verify specific values), these theorems
// hold for ALL natural numbers. The proof is conditional conformance:
// a base case on Zero/PlusZero and an inductive step on AddOne/PlusSucc.
//
// The protocols follow the _TimesNk pattern: plain associated types (no
// where clauses) whose correctness is enforced structurally by the
// conformance definitions. The generic functions below prove universality
// -- the compiler accepts ANY natural or ANY proof -- and the assertEqual
// calls verify the structural properties on concrete instances.

// Theorem 1: 0 + n = n (left zero identity)
// Proved by: extension Zero: AddLeftZero + extension AddOne: AddLeftZero
//
// The generic constraint proves universality: every Natural satisfies
// AddLeftZero, so there exists a ZeroPlusProof for every n.
func useLeftZero<N: AddLeftZero>(_: N.Type) {}
useLeftZero(N0.self)
useLeftZero(N5.self)
useLeftZero(N9.self)

// Verify structural correctness on concrete instances:
assertEqual(N0.ZeroPlusProof.Left.self, Zero.self)    // 0 + 0 = 0
assertEqual(N0.ZeroPlusProof.Right.self, N0.self)
assertEqual(N0.ZeroPlusProof.Total.self, N0.self)

assertEqual(N5.ZeroPlusProof.Left.self, Zero.self)    // 0 + 5 = 5
assertEqual(N5.ZeroPlusProof.Right.self, N5.self)
assertEqual(N5.ZeroPlusProof.Total.self, N5.self)

assertEqual(N9.ZeroPlusProof.Left.self, Zero.self)    // 0 + 9 = 9
assertEqual(N9.ZeroPlusProof.Right.self, N9.self)
assertEqual(N9.ZeroPlusProof.Total.self, N9.self)

// Theorem 2: a + b = c => S(a) + b = S(c) (successor-left shift)
// Proved by: extension PlusZero: SuccLeftAdd + extension PlusSucc: SuccLeftAdd
func useSuccLeftAdd<P: SuccLeftAdd>(_: P.Type) {}
useSuccLeftAdd(PlusZero<N3>.self)
useSuccLeftAdd(PlusSucc<PlusSucc<PlusZero<N2>>>.self)

// 3+0=3 => 4+0=4
assertEqual(PlusZero<N3>.Shifted.Left.self, N4.self)
assertEqual(PlusZero<N3>.Shifted.Right.self, N0.self)
assertEqual(PlusZero<N3>.Shifted.Total.self, N4.self)

// 2+2=4 => 3+2=5
typealias TwoPlusTwo = PlusSucc<PlusSucc<PlusZero<N2>>>
assertEqual(TwoPlusTwo.Shifted.Left.self, N3.self)
assertEqual(TwoPlusTwo.Shifted.Right.self, N2.self)
assertEqual(TwoPlusTwo.Shifted.Total.self, N5.self)

// Theorem 3: a + b = c => b + a = c (commutativity)
// Proved by: extension PlusZero: AddCommutative + extension PlusSucc: AddCommutative
func useCommutativity<P: AddCommutative>(_: P.Type) {}
useCommutativity(PlusZero<N7>.self)
useCommutativity(PlusSucc<PlusSucc<PlusZero<N2>>>.self)
useCommutativity(PlusSucc<PlusSucc<PlusSucc<PlusZero<N3>>>>.self)

// 7+0=7 => 0+7=7
assertEqual(PlusZero<N7>.Commuted.Left.self, N0.self)
assertEqual(PlusZero<N7>.Commuted.Right.self, N7.self)
assertEqual(PlusZero<N7>.Commuted.Total.self, N7.self)

// 2+2=4 => 2+2=4 (symmetric case)
assertEqual(TwoPlusTwo.Commuted.Left.self, N2.self)
assertEqual(TwoPlusTwo.Commuted.Right.self, N2.self)
assertEqual(TwoPlusTwo.Commuted.Total.self, N4.self)

// 3+3=6 => 3+3=6 (symmetric case)
typealias ThreePlusThree = PlusSucc<PlusSucc<PlusSucc<PlusZero<N3>>>>
assertEqual(ThreePlusThree.Commuted.Left.self, N3.self)
assertEqual(ThreePlusThree.Commuted.Right.self, N3.self)
assertEqual(ThreePlusThree.Commuted.Total.self, N6.self)

// MARK: - 16. Associativity of addition (ProofSeed)
//
// Associativity -- (a + b) + c = a + (b + c) -- is a binary theorem: it
// requires TWO addition proofs (one for a+b, one for the result plus c).
// Swift protocols can only do induction on one type parameter. The
// ProofSeed technique solves this by encoding one proof as a seed type
// and doing induction on the other parameter.
//
// Given P1 witnessing a + b = d, wrapping it in c layers of PlusSucc
// (via AddAssociative) yields a proof of a + (b + c) = d + c.
// If we also have P2 witnessing d + c = e, the two Totals agree --
// confirming (a + b) + c = a + (b + c).
//
// Universality is twofold: parametric over P1 (any proof) and inductive
// over c (any natural).

// The generic constraint proves universality: every chain
// AddOne^c(ProofSeed<P>) satisfies AddAssociative.
func useAssociativity<N: AddAssociative>(_: N.Type) {}
useAssociativity(ProofSeed<PlusZero<N0>>.self)
useAssociativity(AddOne<AddOne<ProofSeed<ThreePlusTwo>>>.self)

// Example 1: (3 + 2) + 0 = 3 + (2 + 0) = 5
// P1 = ThreePlusTwo: 3 + 2 = 5, extended by c = 0 (trivial)
typealias Assoc3p2p0 = ProofSeed<ThreePlusTwo>
assertEqual(Assoc3p2p0.AssocProof.Left.self, N3.self)      // a = 3
assertEqual(Assoc3p2p0.AssocProof.Right.self, N2.self)      // b + c = 2 + 0 = 2
assertEqual(Assoc3p2p0.AssocProof.Total.self, N5.self)      // d + c = 5 + 0 = 5
// The other side: (3+2) + 0 = 5 + 0 = 5
assertEqual(Assoc3p2p0.AssocProof.Total.self, PlusZero<N5>.Total.self)

// Example 2: (3 + 2) + 4 = 3 + (2 + 4) = 3 + 6 = 9
// P1 = ThreePlusTwo: 3 + 2 = 5, extended by c = 4
typealias Assoc3p2p4 = AddOne<AddOne<AddOne<AddOne<ProofSeed<ThreePlusTwo>>>>>
assertEqual(Assoc3p2p4.AssocProof.Left.self, N3.self)       // a = 3
assertEqual(Assoc3p2p4.AssocProof.Right.self, N6.self)      // b + c = 2 + 4 = 6
assertEqual(Assoc3p2p4.AssocProof.Total.self, N9.self)      // d + c = 5 + 4 = 9
// The other side: (3+2) + 4 = 5 + 4 = 9
typealias FivePlusFour = PlusSucc<PlusSucc<PlusSucc<PlusSucc<PlusZero<N5>>>>>
assertEqual(Assoc3p2p4.AssocProof.Total.self, FivePlusFour.Total.self)

// Example 3: (2 + 3) + 2 = 2 + (3 + 2) = 2 + 5 = 7
// P1 = TwoPlusThree: 2 + 3 = 5, extended by c = 2
typealias Assoc2p3p2 = AddOne<AddOne<ProofSeed<TwoPlusThree>>>
assertEqual(Assoc2p3p2.AssocProof.Left.self, N2.self)       // a = 2
assertEqual(Assoc2p3p2.AssocProof.Right.self, N5.self)      // b + c = 3 + 2 = 5
assertEqual(Assoc2p3p2.AssocProof.Total.self, N7.self)      // d + c = 5 + 2 = 7
// The other side: (2+3) + 2 = 5 + 2 = 7
typealias FivePlusTwo = PlusSucc<PlusSucc<PlusZero<N5>>>
assertEqual(Assoc2p3p2.AssocProof.Total.self, FivePlusTwo.Total.self)

// MARK: - 17. Universal multiplication theorems (structural induction)
//
// TimesSucc has where clauses that trigger rewrite system explosion when
// composed in inductive protocols. The flat encoding (TimesTick/TimesGroup)
// decomposes each multiplication step into individual successor operations,
// like PlusSucc does for addition. The two encodings coexist -- both
// conform to NaturalProduct.

// -- Flat multiplication proofs --
// For a * b, we need b groups of a ticks each.
// Example: 2 * 3 = 6
//   TimesZero<N2>                                           L=2 R=0 T=0
//   TimesTick<TimesTick<...>>                               L=2 R=0 T=2
//   TimesGroup (marks one copy of 2)                        L=2 R=1 T=2
//   TimesTick<TimesTick<...>>                               L=2 R=1 T=4
//   TimesGroup (marks second copy)                          L=2 R=2 T=4
//   TimesTick<TimesTick<...>>                               L=2 R=2 T=6
//   TimesGroup (marks third copy)                           L=2 R=3 T=6

typealias FlatMul2x0 = TimesZero<N2>
typealias FlatMul2x1 = TimesGroup<TimesTick<TimesTick<FlatMul2x0>>>
typealias FlatMul2x2 = TimesGroup<TimesTick<TimesTick<FlatMul2x1>>>
typealias FlatMul2x3 = TimesGroup<TimesTick<TimesTick<FlatMul2x2>>>

assertEqual(FlatMul2x0.Left.self, N2.self)
assertEqual(FlatMul2x0.Right.self, N0.self)
assertEqual(FlatMul2x0.Total.self, N0.self)     // 2 * 0 = 0

assertEqual(FlatMul2x1.Left.self, N2.self)
assertEqual(FlatMul2x1.Right.self, N1.self)
assertEqual(FlatMul2x1.Total.self, N2.self)     // 2 * 1 = 2

assertEqual(FlatMul2x2.Left.self, N2.self)
assertEqual(FlatMul2x2.Right.self, N2.self)
assertEqual(FlatMul2x2.Total.self, N4.self)     // 2 * 2 = 4

assertEqual(FlatMul2x3.Left.self, N2.self)
assertEqual(FlatMul2x3.Right.self, N3.self)
assertEqual(FlatMul2x3.Total.self, N6.self)     // 2 * 3 = 6

// -- Theorem 1: 0 * n = 0 (left zero annihilation, using TimesGroup) --
// Proved by: extension Zero: MulLeftZero + extension AddOne: MulLeftZero
// With Left = 0, each group has 0 ticks, so just wrap with TimesGroup.
func useLeftZeroMul<N: MulLeftZero>(_: N.Type) {}
useLeftZeroMul(N0.self)
useLeftZeroMul(N5.self)
useLeftZeroMul(N9.self)

// Verify structural correctness:
assertEqual(N0.ZeroTimesProof.Left.self, Zero.self)     // 0 * 0: left = 0
assertEqual(N0.ZeroTimesProof.Right.self, N0.self)      // 0 * 0: right = 0
assertEqual(N0.ZeroTimesProof.Total.self, N0.self)      // 0 * 0 = 0

assertEqual(N5.ZeroTimesProof.Left.self, Zero.self)     // 0 * 5: left = 0
assertEqual(N5.ZeroTimesProof.Right.self, N5.self)      // 0 * 5: right = 5
assertEqual(N5.ZeroTimesProof.Total.self, N0.self)      // 0 * 5 = 0

assertEqual(N9.ZeroTimesProof.Left.self, Zero.self)     // 0 * 9: left = 0
assertEqual(N9.ZeroTimesProof.Right.self, N9.self)      // 0 * 9: right = 9
assertEqual(N9.ZeroTimesProof.Total.self, N0.self)      // 0 * 9 = 0

// -- Theorem 2: a * b = c => S(a) * b = c + b (successor-left multiplication) --
// Proved by: TimesZero/TimesTick/TimesGroup conformances to SuccLeftMul
// Each TimesGroup gains one extra TimesTick, so b groups contribute b extra
// ticks: Total goes from c to c + b.
func useSuccLeftMul<P: SuccLeftMul>(_: P.Type) {}
useSuccLeftMul(TimesZero<N5>.self)
useSuccLeftMul(FlatMul2x3.self)

// TimesZero<N5>: 5 * 0 = 0  =>  6 * 0 = 0
assertEqual(TimesZero<N5>.Distributed.Left.self, N6.self)
assertEqual(TimesZero<N5>.Distributed.Right.self, N0.self)
assertEqual(TimesZero<N5>.Distributed.Total.self, N0.self)

// FlatMul2x3: 2 * 3 = 6  =>  3 * 3 = 6 + 3 = 9
assertEqual(FlatMul2x3.Distributed.Left.self, N3.self)
assertEqual(FlatMul2x3.Distributed.Right.self, N3.self)
assertEqual(FlatMul2x3.Distributed.Total.self, N9.self)

// FlatMul2x2: 2 * 2 = 4  =>  3 * 2 = 4 + 2 = 6
assertEqual(FlatMul2x2.Distributed.Left.self, N3.self)
assertEqual(FlatMul2x2.Distributed.Right.self, N2.self)
assertEqual(FlatMul2x2.Distributed.Total.self, N6.self)

// -- Theorem 4: n * 1 = n (right multiplicative identity) --
// Proved by: extension Zero: MulRightOne + extension AddOne: MulRightOne
// Base case uses TimesGroup<TimesZero<Zero>>; step uses SuccLeftMul.Distributed.
func useMulRightOne<N: MulRightOne>(_: N.Type) {}
useMulRightOne(N0.self)
useMulRightOne(N5.self)
useMulRightOne(N9.self)

// Verify structural correctness:
assertEqual(N0.TimesOneProof.Left.self, N0.self)     // 0 * 1: left = 0
assertEqual(N0.TimesOneProof.Right.self, N1.self)    // 0 * 1: right = 1
assertEqual(N0.TimesOneProof.Total.self, N0.self)    // 0 * 1 = 0

assertEqual(N5.TimesOneProof.Left.self, N5.self)     // 5 * 1: left = 5
assertEqual(N5.TimesOneProof.Right.self, N1.self)    // 5 * 1: right = 1
assertEqual(N5.TimesOneProof.Total.self, N5.self)    // 5 * 1 = 5

assertEqual(N9.TimesOneProof.Left.self, N9.self)     // 9 * 1: left = 9
assertEqual(N9.TimesOneProof.Right.self, N1.self)    // 9 * 1: right = 1
assertEqual(N9.TimesOneProof.Total.self, N9.self)    // 9 * 1 = 9

// -- Theorem 5: 1 * n = n (left multiplicative identity) --
// Proved by: extension Zero: MulLeftOne + extension AddOne: MulLeftOne
// Each step adds one tick (Left = 1) and one group boundary.
func useMulLeftOne<N: MulLeftOne>(_: N.Type) {}
useMulLeftOne(N0.self)
useMulLeftOne(N5.self)
useMulLeftOne(N9.self)

assertEqual(N0.OneTimesProof.Left.self, N1.self)     // 1 * 0: left = 1
assertEqual(N0.OneTimesProof.Right.self, N0.self)    // 1 * 0: right = 0
assertEqual(N0.OneTimesProof.Total.self, N0.self)    // 1 * 0 = 0

assertEqual(N5.OneTimesProof.Left.self, N1.self)     // 1 * 5: left = 1
assertEqual(N5.OneTimesProof.Right.self, N5.self)    // 1 * 5: right = 5
assertEqual(N5.OneTimesProof.Total.self, N5.self)    // 1 * 5 = 5

assertEqual(N9.OneTimesProof.Left.self, N1.self)     // 1 * 9: left = 1
assertEqual(N9.OneTimesProof.Right.self, N9.self)    // 1 * 9: right = 9
assertEqual(N9.OneTimesProof.Total.self, N9.self)    // 1 * 9 = 9

// -- Theorem 3: a * b = b * a (commutativity, per fixed A) --
// For each fixed A (N2, N3, ...), proves A * b = b * A for all b.
// The forward proof constructs A * b directly (A ticks per group).
// The reverse proof chains SuccLeftMul from 0 * A = 0 up to b * A.

// Universality: the generic constraint accepts ANY chain AddOne^b(_MulCommN2Seed)
func useMulCommN2<N: _MulCommN2>(_: N.Type) {}
useMulCommN2(_MulCommN2Seed.self)                                      // b = 0
useMulCommN2(AddOne<AddOne<AddOne<_MulCommN2Seed>>>.self)              // b = 3

// Verify Totals match: 2 * 3 = 3 * 2 = 6
typealias MulComm2x3 = AddOne<AddOne<AddOne<_MulCommN2Seed>>>
assertEqual(MulComm2x3.FwdProof.Total.self, MulComm2x3.RevProof.Total.self)
assertEqual(MulComm2x3.FwdProof.Total.self, N6.self)

// Verify Left/Right are correct:
assertEqual(MulComm2x3.FwdProof.Left.self, N2.self)   // 2 * 3
assertEqual(MulComm2x3.FwdProof.Right.self, N3.self)
assertEqual(MulComm2x3.RevProof.Left.self, N3.self)   // 3 * 2
assertEqual(MulComm2x3.RevProof.Right.self, N2.self)

// Similarly for N3: universality over all b
func useMulCommN3<N: _MulCommN3>(_: N.Type) {}
useMulCommN3(_MulCommN3Seed.self)                                                // b = 0
useMulCommN3(AddOne<AddOne<AddOne<AddOne<_MulCommN3Seed>>>>.self)                // b = 4

// Verify Totals match: 3 * 4 = 4 * 3 = 12
typealias MulComm3x4 = AddOne<AddOne<AddOne<AddOne<_MulCommN3Seed>>>>
assertEqual(MulComm3x4.FwdProof.Total.self, MulComm3x4.RevProof.Total.self)
assertEqual(MulComm3x4.FwdProof.Total.self, N12.self)

// Verify Left/Right are correct:
assertEqual(MulComm3x4.FwdProof.Left.self, N3.self)   // 3 * 4
assertEqual(MulComm3x4.FwdProof.Right.self, N4.self)
assertEqual(MulComm3x4.RevProof.Left.self, N4.self)   // 4 * 3
assertEqual(MulComm3x4.RevProof.Right.self, N3.self)

// -- Macro-generated commutativity proofs (N4, N5) --
// The @MulCommProof macro generates bounded-depth paired proofs:
//   _FwdK witnesses A * K (flat encoding)
//   _RevK witnesses K * A (via SuccLeftMul.Distributed)
// The type checker verifies that both Total types are equal.

@MulCommProof(leftOperand: 4, depth: 5)
enum MulComm4 {}

@MulCommProof(leftOperand: 5, depth: 4)
enum MulComm5 {}

// N4: 4 * 3 = 3 * 4 = 12
assertEqual(MulComm4._Fwd3.Total.self, MulComm4._Rev3.Total.self)
assertEqual(MulComm4._Fwd3.Total.self, N12.self)
assertEqual(MulComm4._Fwd3.Left.self, N4.self)   // 4 * 3
assertEqual(MulComm4._Fwd3.Right.self, N3.self)
assertEqual(MulComm4._Rev3.Left.self, N3.self)   // 3 * 4
assertEqual(MulComm4._Rev3.Right.self, N4.self)

// N5: 5 * 2 = 2 * 5 = 10
assertEqual(MulComm5._Fwd2.Total.self, MulComm5._Rev2.Total.self)
assertEqual(MulComm5._Fwd2.Total.self, N10.self)
assertEqual(MulComm5._Fwd2.Left.self, N5.self)   // 5 * 2
assertEqual(MulComm5._Fwd2.Right.self, N2.self)
assertEqual(MulComm5._Rev2.Left.self, N2.self)   // 2 * 5
assertEqual(MulComm5._Rev2.Right.self, N5.self)

// MARK: - 18. Coinductive streams for irrational numbers
//
// The proofs above represent irrational numbers through bounded-depth
// convergent chains (macro-generated). Coinductive streams provide a
// complementary representation: the continued fraction coefficient
// sequence *itself* as a type.
//
// A CFStream has a Head (the current coefficient) and a Tail (the rest
// of the stream). For periodic continued fractions, self-referential
// types create a productive fixed point: PhiCF.Tail = PhiCF makes the
// type genuinely infinite. Swift resolves this lazily -- .Tail.Tail...Head
// always terminates because each .Tail resolves to a concrete type.

// -- Coefficient extraction --
// PhiCF represents [1; 1, 1, 1, ...]. Every coefficient is 1.
assertEqual(PhiCF.Head.self, N1.self)                         // a_0 = 1
assertEqual(PhiCF.Tail.Head.self, N1.self)                    // a_1 = 1
assertEqual(PhiCF.Tail.Tail.Head.self, N1.self)               // a_2 = 1
assertEqual(PhiCF.Tail.Tail.Tail.Head.self, N1.self)          // a_3 = 1

// Sqrt2CF represents [1; 2, 2, 2, ...]. Transient head, then periodic.
assertEqual(Sqrt2CF.Head.self, N1.self)                       // a_0 = 1
assertEqual(Sqrt2CF.Tail.Head.self, N2.self)                  // a_1 = 2
assertEqual(Sqrt2CF.Tail.Tail.Head.self, N2.self)             // a_2 = 2
assertEqual(Sqrt2CF.Tail.Tail.Tail.Head.self, N2.self)        // a_3 = 2

// -- Structural properties: fixed points --
// The self-referential definition PhiCF.Tail = PhiCF IS the coinductive
// structure. The type is its own tail -- unwinding it always yields itself.
assertStreamEqual(PhiCF.Tail.self, PhiCF.self)
assertStreamEqual(PhiCF.Tail.Tail.self, PhiCF.self)
assertStreamEqual(PhiCF.Tail.Tail.Tail.self, PhiCF.self)

// Sqrt2Periodic is similarly self-referential:
assertStreamEqual(Sqrt2Periodic.Tail.self, Sqrt2Periodic.self)
assertStreamEqual(Sqrt2Periodic.Tail.Tail.self, Sqrt2Periodic.self)

// Sqrt2CF's tail enters the periodic part:
assertStreamEqual(Sqrt2CF.Tail.self, Sqrt2Periodic.self)
assertStreamEqual(Sqrt2CF.Tail.Tail.self, Sqrt2Periodic.self)

// -- Universal unfold theorems --
// PhiUnfold proves that PhiCF unfolds to itself at ANY depth, not just
// the specific depths tested above. The generic constraint accepts any
// chain AddOne^n(PhiUnfoldSeed), proving universality by induction.
func usePhiUnfold<N: PhiUnfold>(_: N.Type) {}
usePhiUnfold(PhiUnfoldSeed.self)                                         // depth 0
usePhiUnfold(AddOne<AddOne<AddOne<PhiUnfoldSeed>>>.self)                // depth 3
usePhiUnfold(AddOne<AddOne<AddOne<AddOne<AddOne<PhiUnfoldSeed>>>>>.self) // depth 5

// Verify the Unfolded type is PhiCF at specific depths:
assertStreamEqual(PhiUnfoldSeed.Unfolded.self, PhiCF.self)                          // depth 0
assertStreamEqual(AddOne<PhiUnfoldSeed>.Unfolded.self, PhiCF.self)                  // depth 1
assertStreamEqual(AddOne<AddOne<PhiUnfoldSeed>>.Unfolded.self, PhiCF.self)          // depth 2
assertStreamEqual(AddOne<AddOne<AddOne<PhiUnfoldSeed>>>.Unfolded.self, PhiCF.self)  // depth 3

// Similarly for Sqrt2Periodic:
func useSqrt2PeriodicUnfold<N: Sqrt2PeriodicUnfold>(_: N.Type) {}
useSqrt2PeriodicUnfold(Sqrt2PeriodicUnfoldSeed.self)
useSqrt2PeriodicUnfold(AddOne<AddOne<AddOne<Sqrt2PeriodicUnfoldSeed>>>.self)

assertStreamEqual(Sqrt2PeriodicUnfoldSeed.Unfolded.self, Sqrt2Periodic.self)
assertStreamEqual(AddOne<Sqrt2PeriodicUnfoldSeed>.Unfolded.self, Sqrt2Periodic.self)
assertStreamEqual(AddOne<AddOne<Sqrt2PeriodicUnfoldSeed>>.Unfolded.self, Sqrt2Periodic.self)

// -- Connection to existing convergent proofs --
// The stream coefficients match the values used by the macro-generated
// convergent constructions. GCFConv0<B0> takes the first CF coefficient
// as its type parameter; for depth-0 convergents, h_0 = b_0.
//
// Golden ratio: PhiCF.Head = 1, matching the all-ones CF [1; 1, 1, ...]
assertEqual(PhiCF.Head.self, GoldenRatioProof._CF0.P.self)    // both N1
// Sqrt2: Sqrt2CF.Head = 1, matching [1; 2, 2, ...]
assertEqual(Sqrt2CF.Head.self, Sqrt2Proof._CF0.P.self)         // both N1

// MARK: - 19. Distributivity of multiplication over addition
//
// Distributivity -- a * (b + c) = a*b + a*c -- bridges the sum and product
// witness systems. The flat encoding makes it natural: a * (b + c) has
// (b + c) groups of a ticks, which is b groups (the a*b part) followed by
// c groups (the a*c part).
//
// ProductSeed<Q> wraps an existing product proof Q (for a*b). TimesTick and
// TimesGroup layers on top represent a*c. The MulDistributive protocol
// tracks a NaturalSum witness through the product proof:
//   - ProductSeed<Q>: DistrSum = PlusZero<Q.Total>  (a*b + 0 = a*b)
//   - TimesTick:      DistrSum = PlusSucc<...>       (adds 1 to the sum)
//   - TimesGroup:     DistrSum unchanged             (group boundary)
//
// At the end, DistrSum witnesses a*b + a*c = a*(b+c).

// The generic constraint proves universality: every MulDistributive proof
// carries a DistrSum witnessing the distributive decomposition.
func useDistributivity<P: MulDistributive>(_: P.Type) {}

// Example 1: 2 * (1 + 1) = 2*1 + 2*1 = 2 + 2 = 4
// Start with FlatMul2x1 (2*1 = 2), add 1 group of 2 ticks.
typealias Distr2x1p1 = TimesGroup<TimesTick<TimesTick<ProductSeed<FlatMul2x1>>>>

assertEqual(Distr2x1p1.Left.self, N2.self)              // a = 2
assertEqual(Distr2x1p1.Right.self, N2.self)             // b + c = 1 + 1 = 2
assertEqual(Distr2x1p1.Total.self, N4.self)             // 2 * 2 = 4

assertEqual(Distr2x1p1.DistrSum.Left.self, N2.self)     // a*b = 2*1 = 2
assertEqual(Distr2x1p1.DistrSum.Right.self, N2.self)    // a*c = 2*1 = 2
assertEqual(Distr2x1p1.DistrSum.Total.self, N4.self)    // 2 + 2 = 4

useDistributivity(Distr2x1p1.self)

// Example 2: 3 * (2 + 1) = 3*2 + 3*1 = 6 + 3 = 9
// Define flat proofs for 3*0, 3*1, 3*2 (3 ticks per group).
typealias FlatMul3x0 = TimesZero<N3>
typealias FlatMul3x1 = TimesGroup<TimesTick<TimesTick<TimesTick<FlatMul3x0>>>>
typealias FlatMul3x2 = TimesGroup<TimesTick<TimesTick<TimesTick<FlatMul3x1>>>>

assertEqual(FlatMul3x2.Left.self, N3.self)
assertEqual(FlatMul3x2.Right.self, N2.self)
assertEqual(FlatMul3x2.Total.self, N6.self)             // 3 * 2 = 6

// Stack 1 group of 3 ticks on ProductSeed<FlatMul3x2>.
typealias Distr3x2p1 = TimesGroup<TimesTick<TimesTick<TimesTick<ProductSeed<FlatMul3x2>>>>>

assertEqual(Distr3x2p1.Left.self, N3.self)              // a = 3
assertEqual(Distr3x2p1.Right.self, N3.self)             // b + c = 2 + 1 = 3
assertEqual(Distr3x2p1.Total.self, N9.self)             // 3 * 3 = 9

assertEqual(Distr3x2p1.DistrSum.Left.self, N6.self)     // a*b = 3*2 = 6
assertEqual(Distr3x2p1.DistrSum.Right.self, N3.self)    // a*c = 3*1 = 3
assertEqual(Distr3x2p1.DistrSum.Total.self, N9.self)    // 6 + 3 = 9

useDistributivity(Distr3x2p1.self)

// Example 3: 2 * (2 + 3) = 2*2 + 2*3 = 4 + 6 = 10
// Stack 3 groups of 2 ticks on ProductSeed<FlatMul2x2>.
typealias Distr2x2p3 = TimesGroup<TimesTick<TimesTick<
                          TimesGroup<TimesTick<TimesTick<
                            TimesGroup<TimesTick<TimesTick<
                              ProductSeed<FlatMul2x2>>>>>>>>>>

assertEqual(Distr2x2p3.Left.self, N2.self)              // a = 2
assertEqual(Distr2x2p3.Right.self, N5.self)             // b + c = 2 + 3 = 5
assertEqual(Distr2x2p3.Total.self, N10.self)            // 2 * 5 = 10

assertEqual(Distr2x2p3.DistrSum.Left.self, N4.self)     // a*b = 2*2 = 4
assertEqual(Distr2x2p3.DistrSum.Right.self, N6.self)    // a*c = 2*3 = 6
assertEqual(Distr2x2p3.DistrSum.Total.self, N10.self)   // 4 + 6 = 10

useDistributivity(Distr2x2p3.self)

// MARK: - 20. Algebraic identity: n*(n+2) + 1 = (n+1)^2
//
// The Wallis product uses the factor correspondence (2k-1)(2k+1) + 1 = (2k)^2
// at each step. This is an instance of the universal algebraic identity
// n*(n+2) + 1 = (n+1)^2 -- the "difference of squares" identity.
//
// The algebraic reason it holds: both sides decompose via a shared base n*(n+1).
//   (n+1)^2     = n*(n+1) + (n+1)    [SuccLeftMul: S(n) * (n+1) = n*(n+1) + (n+1)]
//   n*(n+2)     = n*((n+1)+1)
//               = n*(n+1) + n*1
//               = n*(n+1) + n         [distributivity + MulRightOne]
//   Difference  = (n+1) - n = 1
//
// Both share n*(n+1) as a common term. The remainders differ by exactly 1.
// Below we demonstrate this at n=1 and n=2 using SuccLeftMul and MulDistributive.

// -- n = 1: 1*3 + 1 = 4 = 2*2 --
// Shared base: 1*2 = 2  (FlatMul1x2 below)
// (n+1)^2 = 2*2: FlatMul1x2.Distributed witnesses 2*2 = 1*2 + 2 = 2 + 2 = 4
// n*(n+2) = 1*3: ProductSeed<FlatMul1x2> + 1 group of 1 tick = 1*(2+1) = 2 + 1 = 3

typealias FlatMul1x0 = TimesZero<N1>
typealias FlatMul1x1 = TimesGroup<TimesTick<FlatMul1x0>>
typealias FlatMul1x2 = TimesGroup<TimesTick<FlatMul1x1>>

assertEqual(FlatMul1x2.Total.self, N2.self)                      // 1 * 2 = 2

// SuccLeftMul: 1*2 = 2 => 2*2 = 2 + 2 = 4
assertEqual(FlatMul1x2.Distributed.Left.self, N2.self)           // S(1) = 2
assertEqual(FlatMul1x2.Distributed.Right.self, N2.self)          // right = 2
assertEqual(FlatMul1x2.Distributed.Total.self, N4.self)          // 2*2 = 4

// Distributivity: 1*(2+1) = 1*2 + 1*1 = 2 + 1 = 3
typealias Distr1x2p1 = TimesGroup<TimesTick<ProductSeed<FlatMul1x2>>>
assertEqual(Distr1x2p1.Total.self, N3.self)                      // 1*3 = 3
assertEqual(Distr1x2p1.DistrSum.Left.self, N2.self)              // 1*2 = 2
assertEqual(Distr1x2p1.DistrSum.Right.self, N1.self)             // 1*1 = 1
assertEqual(Distr1x2p1.DistrSum.Total.self, N3.self)             // 2 + 1 = 3

// The identity: 1*3 + 1 = 4 = 2*2
typealias DiffSq1 = PlusSucc<PlusZero<N3>>                       // 3 + 1 = 4
assertEqual(DiffSq1.Total.self, FlatMul1x2.Distributed.Total.self)  // 4 = 4 ✓

// -- n = 2: 2*4 + 1 = 9 = 3*3 --
// Shared base: 2*3 = 6  (FlatMul2x3 from section 17)
// (n+1)^2 = 3*3: FlatMul2x3.Distributed witnesses 3*3 = 2*3 + 3 = 6 + 3 = 9
// n*(n+2) = 2*4: ProductSeed<FlatMul2x3> + 1 group of 2 ticks = 2*(3+1) = 6 + 2 = 8

// SuccLeftMul: 2*3 = 6 => 3*3 = 6 + 3 = 9
assertEqual(FlatMul2x3.Distributed.Left.self, N3.self)           // S(2) = 3
assertEqual(FlatMul2x3.Distributed.Right.self, N3.self)          // right = 3
assertEqual(FlatMul2x3.Distributed.Total.self, N9.self)          // 3*3 = 9

// Distributivity: 2*(3+1) = 2*3 + 2*1 = 6 + 2 = 8
typealias Distr2x3p1 = TimesGroup<TimesTick<TimesTick<ProductSeed<FlatMul2x3>>>>
assertEqual(Distr2x3p1.Total.self, N8.self)                      // 2*4 = 8
assertEqual(Distr2x3p1.DistrSum.Left.self, N6.self)              // 2*3 = 6
assertEqual(Distr2x3p1.DistrSum.Right.self, N2.self)             // 2*1 = 2
assertEqual(Distr2x3p1.DistrSum.Total.self, N8.self)             // 6 + 2 = 8

// The identity: 2*4 + 1 = 9 = 3*3
typealias DiffSq2 = PlusSucc<PlusZero<N8>>                       // 8 + 1 = 9
assertEqual(DiffSq2.Total.self, FlatMul2x3.Distributed.Total.self)  // 9 = 9 ✓

// Both decompositions share FlatMul2x3 (the proof of 2*3 = 6):
//   3*3 = 6 + 3  (SuccLeftMul adds Right = 3)
//   2*4 = 6 + 2  (distributivity adds 2 ticks = one group of Left = 2)
// The remainders (3 vs 2) differ by 1 -- that's the structural reason.

// MARK: - 21. Cassini identity for Fibonacci numbers
//
// The Cassini identity is a number-theoretic theorem about Fibonacci:
//   F(n-1)*F(n+1) - F(n)^2 = (-1)^n
//
// In naturals (avoiding negatives), the sign alternates which side gets +1:
//   Even n: F(n-1)*F(n+1) = F(n)^2 + 1
//   Odd n:  F(n-1)*F(n+1) + 1 = F(n)^2
//
// The key step uses distributivity:
//   F(n+1)*F(n-1) = (F(n) + F(n-1)) * F(n-1)    [Fibonacci recurrence]
//                 = F(n)*F(n-1) + F(n-1)^2        [distributivity]
//
// This relates the cross-product at step n to the square and cross-product
// at step n-1. It's a theorem ABOUT Fibonacci, not just a computation OF it.

// -- n = 2 (even): F(1)*F(3) = F(2)^2 + 1 => 1*2 = 1 + 1 => 2 = 2 --
// F(1)=1, F(2)=1, F(3)=2

// F(2)^2 = 1*1 = 1 (MulRightOne)
assertEqual(N1.TimesOneProof.Total.self, N1.self)                 // 1*1 = 1

// F(1)*F(3) = 1*2 = 2 (MulLeftOne)
assertEqual(N2.OneTimesProof.Total.self, N2.self)                 // 1*2 = 2

// 1 + 1 = 2
typealias Cassini2 = PlusSucc<PlusZero<N1>>
assertEqual(Cassini2.Total.self, N2.OneTimesProof.Total.self)     // F(2)^2 + 1 = F(1)*F(3)

// -- n = 3 (odd): F(2)*F(4) + 1 = F(3)^2 => 1*3 + 1 = 4 = 2*2 --
// F(2)=1, F(3)=2, F(4)=3
// This is also the n=1 difference-of-squares identity!

// F(3)^2 = 2*2 = 4 (FlatMul2x2 from section 17)
assertEqual(FlatMul2x2.Total.self, N4.self)                       // 2*2 = 4

// F(2)*F(4) = 1*3 = 3 (Distr1x2p1 from section 20)
assertEqual(Distr1x2p1.Total.self, N3.self)                       // 1*3 = 3

// Distributive decomposition: F(4)*F(2) = (F(3)+F(2))*F(2) = F(3)*F(2) + F(2)^2
// = (3)*1 = (2+1)*1 = 2*1 + 1*1 = 2 + 1 = 3
// Using Distr1x2p1.DistrSum: Left=2 (F(3)*F(2)), Right=1 (F(2)^2), Total=3
assertEqual(Distr1x2p1.DistrSum.Left.self, N2.self)               // F(3)*F(2) = 2
assertEqual(Distr1x2p1.DistrSum.Right.self, N1.self)              // F(2)^2 = 1

// 3 + 1 = 4
typealias Cassini3 = PlusSucc<PlusZero<N3>>
assertEqual(Cassini3.Total.self, FlatMul2x2.Total.self)           // F(2)*F(4) + 1 = F(3)^2

// -- n = 4 (even): F(3)*F(5) = F(4)^2 + 1 => 2*5 = 9 + 1 = 10 --
// F(3)=2, F(4)=3, F(5)=5

// F(4)^2 = 3*3: use SuccLeftMul on FlatMul2x3
assertEqual(FlatMul2x3.Distributed.Total.self, N9.self)           // 3*3 = 9

// F(3)*F(5) = 2*5 = 10: 5 groups of 2 ticks
typealias FlatMul2x4 = TimesGroup<TimesTick<TimesTick<FlatMul2x3>>>
typealias FlatMul2x5 = TimesGroup<TimesTick<TimesTick<FlatMul2x4>>>
assertEqual(FlatMul2x5.Total.self, N10.self)                      // 2*5 = 10

// Distributive decomposition: F(5)*F(3) = (F(4)+F(3))*F(3) = F(4)*F(3) + F(3)^2
// 5*2 = (3+2)*2. Rewrite as: 2*(3+2) = 2*3 + 2*2 = 6 + 4 = 10
// (Using commutativity of the natural number product, not the proof)
assertEqual(Distr2x2p3.DistrSum.Left.self, N4.self)               // 2*2 = F(3)^2 = 4
assertEqual(Distr2x2p3.DistrSum.Right.self, N6.self)              // 2*3 = F(4)*F(3) = 6
assertEqual(Distr2x2p3.DistrSum.Total.self, N10.self)             // 4 + 6 = 10

// 9 + 1 = 10
typealias Cassini4 = PlusSucc<PlusZero<N9>>
assertEqual(Cassini4.Total.self, FlatMul2x5.Total.self)           // F(4)^2 + 1 = F(3)*F(5)

// MARK: - Epilogue
//
// If you're reading this, the program compiled and exited cleanly. That
// means every assertEqual call above unified its type arguments and every
// witness type satisfied its protocol constraints. The compiler verified
// 100+ mathematical facts about natural numbers, their arithmetic,
// continued fractions, the Leibniz series, the Wallis product (with its
// difference-of-squares factor correspondence), the golden ratio /
// Fibonacci correspondence, the sqrt(2) CF / matrix construction, four
// universal addition theorems (left zero identity, successor-left shift,
// commutativity, and associativity), six universal multiplication
// theorems (left zero annihilation, successor-left multiplication,
// per-A commutativity -- including macro-generated proofs for N4 and N5 --
// right and left multiplicative identity, and distributivity over
// addition), and coinductive streams for irrational
// numbers (PhiCF, Sqrt2CF with universal unfold theorems) -- all without
// executing a single computation at runtime.
