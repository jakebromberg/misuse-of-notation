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

// MARK: - 3. Continued fractions and pi (macro-generated proof)

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
enum PiConvergenceProof {}

// The macro generated CF convergents Convergent0...Convergent3 and Leibniz partial sums
// LeibnizSum1...LeibnizSum4, plus all intermediate multiplication and addition witnesses,
// as members of PiConvergenceProof. Verify the computed values:

assertEqual(PiConvergenceProof.Convergent0.P.self, N1.self)    // h_0 = 1
assertEqual(PiConvergenceProof.Convergent0.Q.self, N1.self)    // k_0 = 1
assertEqual(PiConvergenceProof.Convergent1.P.self, N3.self)    // h_1 = 3
assertEqual(PiConvergenceProof.Convergent1.Q.self, N2.self)    // k_1 = 2
assertEqual(PiConvergenceProof.Convergent2.P.self, N15.self)   // h_2 = 15
assertEqual(PiConvergenceProof.Convergent2.Q.self, N13.self)   // k_2 = 13
assertEqual(PiConvergenceProof.Convergent3.P.self, N105.self)  // h_3 = 105
assertEqual(PiConvergenceProof.Convergent3.Q.self, N76.self)   // k_3 = 76

assertEqual(PiConvergenceProof.LeibnizSum1.P.self, N1.self)    // S_1 = 1/1
assertEqual(PiConvergenceProof.LeibnizSum1.Q.self, N1.self)
assertEqual(PiConvergenceProof.LeibnizSum2.P.self, N2.self)    // S_2 = 2/3
assertEqual(PiConvergenceProof.LeibnizSum2.Q.self, N3.self)
assertEqual(PiConvergenceProof.LeibnizSum3.P.self, N13.self)   // S_3 = 13/15
assertEqual(PiConvergenceProof.LeibnizSum3.Q.self, N15.self)
assertEqual(PiConvergenceProof.LeibnizSum4.P.self, N76.self)   // S_4 = 76/105
assertEqual(PiConvergenceProof.LeibnizSum4.Q.self, N105.self)

// The macro also generated piCorrespondenceCheck(), a function whose
// compilation verifies the Brouncker-Leibniz correspondence at each depth:
//   assertEqual(Convergent1.P, LeibnizSum2.Q)  -- h_1 = S_2 denominator (3 = 3)
//   assertEqual(Convergent1.Q, LeibnizSum2.P)  -- k_1 = S_2 numerator   (2 = 2)
//   assertEqual(Convergent2.P, LeibnizSum3.Q)  -- h_2 = S_3 denominator (15 = 15)
//   assertEqual(Convergent2.Q, LeibnizSum3.P)  -- k_2 = S_3 numerator   (13 = 13)
//   assertEqual(Convergent3.P, LeibnizSum4.Q)  -- h_3 = S_4 denominator (105 = 105)
//   assertEqual(Convergent3.Q, LeibnizSum4.P)  -- k_3 = S_4 numerator   (76 = 76)
//
// These type equalities prove that Brouncker's CF for 4/pi and the Leibniz
// series for pi/4 produce reciprocal rational approximations at each depth.
// Since both sequences converge, and their values agree, they converge to
// the same limit: pi.

// MARK: - 4. Wallis product (macro-generated proof)

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
enum WallisProductProof {}

// Verify W_0 = 1/1:
assertEqual(WallisProductProof.Wallis0.P.self, N1.self)
assertEqual(WallisProductProof.Wallis0.Q.self, N1.self)

// Verify W_1 = 4/3:
assertEqual(WallisProductProof.Wallis1.P.self, N4.self)
assertEqual(WallisProductProof.Wallis1.Q.self, N3.self)

// MARK: - 5. Fibonacci at the type level (macro-generated proof)

// The FibonacciVerified protocol uses a where clause on its SumWitness
// associated type to force Next == Prev + Current. Each FibonacciStep
// carries a NaturalSum witness proving the Fibonacci recurrence.
//
// Writing witness chains by hand is tedious -- the #fibonacciProof macro
// computes Fibonacci numbers as regular integers at compile time, then
// emits PlusSucc/PlusZero witness chains that the type checker verifies.

@FibonacciProof(upTo: 10)
enum FibonacciProof {}

// The macro generated FibonacciStep chains Fibonacci1 through Fibonacci10 as members
// of FibonacciProof. Verify:
assertEqual(Fibonacci0.Current.self, N0.self)            // F(0) = 0
assertEqual(Fibonacci0.Next.self, N1.self)               // F(1) = 1
assertEqual(FibonacciProof.Fibonacci1.Current.self, N1.self)  // F(1) = 1
assertEqual(FibonacciProof.Fibonacci2.Current.self, N1.self)  // F(2) = 1
assertEqual(FibonacciProof.Fibonacci3.Current.self, N2.self)  // F(3) = 2
assertEqual(FibonacciProof.Fibonacci4.Current.self, N3.self)  // F(4) = 3
assertEqual(FibonacciProof.Fibonacci5.Current.self, N5.self)  // F(5) = 5
assertEqual(FibonacciProof.Fibonacci6.Current.self, N8.self)  // F(6) = 8

// MARK: - 6. Golden ratio and Fibonacci (macro-generated proof)

// The golden ratio phi = (1 + sqrt(5))/2 has the simplest continued fraction:
//   phi = [1; 1, 1, 1, ...]
//
// The CF recurrence with a=1, b=1 is just h_n = h_{n-1} + h_{n-2} -- the
// Fibonacci recurrence. The convergents h_n/k_n satisfy:
//   h_n = F(n+2),  k_n = F(n+1)
//
// The @GoldenRatioProof macro constructs both sequences independently:
//   1. FibonacciStep witness chains proving F(i-1) + F(i) = F(i+1)
//   2. GCFConvergentStep convergents for the all-ones CF
// Then generates assertEqual calls verifying the correspondence.

@GoldenRatioProof(depth: 5)
enum GoldenRatioProof {}

// Verify CF convergents match Fibonacci values:
assertEqual(GoldenRatioProof.Convergent0.P.self, N1.self)   // h_0 = 1 = F(2)
assertEqual(GoldenRatioProof.Convergent0.Q.self, N1.self)   // k_0 = 1 = F(1)
assertEqual(GoldenRatioProof.Convergent1.P.self, N2.self)   // h_1 = 2 = F(3)
assertEqual(GoldenRatioProof.Convergent1.Q.self, N1.self)   // k_1 = 1 = F(2)
assertEqual(GoldenRatioProof.Convergent2.P.self, N3.self)   // h_2 = 3 = F(4)
assertEqual(GoldenRatioProof.Convergent2.Q.self, N2.self)   // k_2 = 2 = F(3)
assertEqual(GoldenRatioProof.Convergent3.P.self, N5.self)   // h_3 = 5 = F(5)
assertEqual(GoldenRatioProof.Convergent3.Q.self, N3.self)   // k_3 = 3 = F(4)
assertEqual(GoldenRatioProof.Convergent4.P.self, N8.self)   // h_4 = 8 = F(6)
assertEqual(GoldenRatioProof.Convergent4.Q.self, N5.self)   // k_4 = 5 = F(5)
assertEqual(GoldenRatioProof.Convergent5.P.self, N13.self)  // h_5 = 13 = F(7)
assertEqual(GoldenRatioProof.Convergent5.Q.self, N8.self)   // k_5 = 8 = F(6)

// MARK: - 7. sqrt(2) CF and matrix construction (macro-generated proof)

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
//   1. CF convergents via GCFConvergentStep (three-term recurrence)
//   2. Matrix powers via Sqrt2MatStep (iterated left-multiplication)
// Then generates assertEqual calls proving they produce the same values.

@Sqrt2ConvergenceProof(depth: 3)
enum Sqrt2ConvergenceProof {}

// Verify CF convergents:
assertEqual(Sqrt2ConvergenceProof.Convergent0.P.self, N1.self)    // h_0 = 1
assertEqual(Sqrt2ConvergenceProof.Convergent0.Q.self, N1.self)    // k_0 = 1
assertEqual(Sqrt2ConvergenceProof.Convergent1.P.self, N3.self)    // h_1 = 3
assertEqual(Sqrt2ConvergenceProof.Convergent1.Q.self, N2.self)    // k_1 = 2
assertEqual(Sqrt2ConvergenceProof.Convergent2.P.self, N7.self)    // h_2 = 7
assertEqual(Sqrt2ConvergenceProof.Convergent2.Q.self, N5.self)    // k_2 = 5
assertEqual(Sqrt2ConvergenceProof.Convergent3.P.self, N17.self)   // h_3 = 17
assertEqual(Sqrt2ConvergenceProof.Convergent3.Q.self, N12.self)   // k_3 = 12

// Verify matrix entries match:
assertEqual(Sqrt2ConvergenceProof.MatrixPower0.A.self, N1.self)   // MAT0 top-left = h_0 = 1
assertEqual(Sqrt2ConvergenceProof.MatrixPower0.B.self, N1.self)   // MAT0 top-right = k_0 = 1
assertEqual(Sqrt2ConvergenceProof.MatrixPower1.A.self, N3.self)   // MAT1 top-left = h_1 = 3
assertEqual(Sqrt2ConvergenceProof.MatrixPower1.B.self, N2.self)   // MAT1 top-right = k_1 = 2
assertEqual(Sqrt2ConvergenceProof.MatrixPower2.A.self, N7.self)   // MAT2 top-left = h_2 = 7
assertEqual(Sqrt2ConvergenceProof.MatrixPower2.B.self, N5.self)   // MAT2 top-right = k_2 = 5
assertEqual(Sqrt2ConvergenceProof.MatrixPower3.A.self, N17.self)  // MAT3 top-left = h_3 = 17
assertEqual(Sqrt2ConvergenceProof.MatrixPower3.B.self, N12.self)  // MAT3 top-right = k_3 = 12

// MARK: - 8. Universal addition theorems (structural induction)
//
// Unlike the proofs above (which verify specific values), these theorems
// hold for ALL natural numbers. The proof is conditional conformance:
// a base case on Zero/PlusZero and an inductive step on AddOne/PlusSucc.
//
// The protocols follow the TimesNk pattern: plain associated types (no
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
// Proved by: extension PlusZero: SuccessorLeftAdd + extension PlusSucc: SuccessorLeftAdd
func useSuccessorLeftAdd<P: SuccessorLeftAdd>(_: P.Type) {}
useSuccessorLeftAdd(PlusZero<N3>.self)
useSuccessorLeftAdd(PlusSucc<PlusSucc<PlusZero<N2>>>.self)

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

// MARK: - 9. Associativity of addition (ProofSeed)
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
typealias Associative3Plus2Plus0 = ProofSeed<ThreePlusTwo>
assertEqual(Associative3Plus2Plus0.AssociativeProof.Left.self, N3.self)      // a = 3
assertEqual(Associative3Plus2Plus0.AssociativeProof.Right.self, N2.self)      // b + c = 2 + 0 = 2
assertEqual(Associative3Plus2Plus0.AssociativeProof.Total.self, N5.self)      // d + c = 5 + 0 = 5
// The other side: (3+2) + 0 = 5 + 0 = 5
assertEqual(Associative3Plus2Plus0.AssociativeProof.Total.self, PlusZero<N5>.Total.self)

// Example 2: (3 + 2) + 4 = 3 + (2 + 4) = 3 + 6 = 9
// P1 = ThreePlusTwo: 3 + 2 = 5, extended by c = 4
typealias Associative3Plus2Plus4 = AddOne<AddOne<AddOne<AddOne<ProofSeed<ThreePlusTwo>>>>>
assertEqual(Associative3Plus2Plus4.AssociativeProof.Left.self, N3.self)       // a = 3
assertEqual(Associative3Plus2Plus4.AssociativeProof.Right.self, N6.self)      // b + c = 2 + 4 = 6
assertEqual(Associative3Plus2Plus4.AssociativeProof.Total.self, N9.self)      // d + c = 5 + 4 = 9
// The other side: (3+2) + 4 = 5 + 4 = 9
typealias FivePlusFour = PlusSucc<PlusSucc<PlusSucc<PlusSucc<PlusZero<N5>>>>>
assertEqual(Associative3Plus2Plus4.AssociativeProof.Total.self, FivePlusFour.Total.self)

// Example 3: (2 + 3) + 2 = 2 + (3 + 2) = 2 + 5 = 7
// P1 = TwoPlusThree: 2 + 3 = 5, extended by c = 2
typealias Associative2Plus3Plus2 = AddOne<AddOne<ProofSeed<TwoPlusThree>>>
assertEqual(Associative2Plus3Plus2.AssociativeProof.Left.self, N2.self)       // a = 2
assertEqual(Associative2Plus3Plus2.AssociativeProof.Right.self, N5.self)      // b + c = 3 + 2 = 5
assertEqual(Associative2Plus3Plus2.AssociativeProof.Total.self, N7.self)      // d + c = 5 + 2 = 7
// The other side: (2+3) + 2 = 5 + 2 = 7
typealias FivePlusTwo = PlusSucc<PlusSucc<PlusZero<N5>>>
assertEqual(Associative2Plus3Plus2.AssociativeProof.Total.self, FivePlusTwo.Total.self)

// MARK: - 10. Universal multiplication theorems (structural induction)
//
// The NaturalProduct protocol witnesses Left * Right = Total. Two encodings
// exist: TimesSucc (compositional, but its where clauses trigger rewrite
// system explosion in inductive contexts) and the flat encoding
// (TimesTick/TimesGroup) used here. The flat encoding decomposes each step
// into primitives without where clauses, enabling universal theorems.

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

typealias FlatProduct2Times0 = TimesZero<N2>
typealias FlatProduct2Times1 = TimesGroup<TimesTick<TimesTick<FlatProduct2Times0>>>
typealias FlatProduct2Times2 = TimesGroup<TimesTick<TimesTick<FlatProduct2Times1>>>
typealias FlatProduct2Times3 = TimesGroup<TimesTick<TimesTick<FlatProduct2Times2>>>

assertEqual(FlatProduct2Times0.Left.self, N2.self)
assertEqual(FlatProduct2Times0.Right.self, N0.self)
assertEqual(FlatProduct2Times0.Total.self, N0.self)     // 2 * 0 = 0

assertEqual(FlatProduct2Times1.Left.self, N2.self)
assertEqual(FlatProduct2Times1.Right.self, N1.self)
assertEqual(FlatProduct2Times1.Total.self, N2.self)     // 2 * 1 = 2

assertEqual(FlatProduct2Times2.Left.self, N2.self)
assertEqual(FlatProduct2Times2.Right.self, N2.self)
assertEqual(FlatProduct2Times2.Total.self, N4.self)     // 2 * 2 = 4

assertEqual(FlatProduct2Times3.Left.self, N2.self)
assertEqual(FlatProduct2Times3.Right.self, N3.self)
assertEqual(FlatProduct2Times3.Total.self, N6.self)     // 2 * 3 = 6

// -- Theorem 1: 0 * n = 0 (left zero annihilation, using TimesGroup) --
// Proved by: extension Zero: MultiplicationLeftZero + extension AddOne: MultiplicationLeftZero
// With Left = 0, each group has 0 ticks, so just wrap with TimesGroup.
func useMultiplicationLeftZero<N: MultiplicationLeftZero>(_: N.Type) {}
useMultiplicationLeftZero(N0.self)
useMultiplicationLeftZero(N5.self)
useMultiplicationLeftZero(N9.self)

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
// Proved by: TimesZero/TimesTick/TimesGroup conformances to SuccessorLeftMultiplication
// Each TimesGroup gains one extra TimesTick, so b groups contribute b extra
// ticks: Total goes from c to c + b.
func useSuccessorLeftMultiplication<P: SuccessorLeftMultiplication>(_: P.Type) {}
useSuccessorLeftMultiplication(TimesZero<N5>.self)
useSuccessorLeftMultiplication(FlatProduct2Times3.self)

// TimesZero<N5>: 5 * 0 = 0  =>  6 * 0 = 0
assertEqual(TimesZero<N5>.Distributed.Left.self, N6.self)
assertEqual(TimesZero<N5>.Distributed.Right.self, N0.self)
assertEqual(TimesZero<N5>.Distributed.Total.self, N0.self)

// FlatProduct2Times3: 2 * 3 = 6  =>  3 * 3 = 6 + 3 = 9
assertEqual(FlatProduct2Times3.Distributed.Left.self, N3.self)
assertEqual(FlatProduct2Times3.Distributed.Right.self, N3.self)
assertEqual(FlatProduct2Times3.Distributed.Total.self, N9.self)

// FlatProduct2Times2: 2 * 2 = 4  =>  3 * 2 = 4 + 2 = 6
assertEqual(FlatProduct2Times2.Distributed.Left.self, N3.self)
assertEqual(FlatProduct2Times2.Distributed.Right.self, N2.self)
assertEqual(FlatProduct2Times2.Distributed.Total.self, N6.self)

// -- Theorem 4: n * 1 = n (right multiplicative identity) --
// Proved by: extension Zero: MultiplicationRightOne + extension AddOne: MultiplicationRightOne
// Base case uses TimesGroup<TimesZero<Zero>>; step uses SuccessorLeftMultiplication.Distributed.
func useMultiplicationRightOne<N: MultiplicationRightOne>(_: N.Type) {}
useMultiplicationRightOne(N0.self)
useMultiplicationRightOne(N5.self)
useMultiplicationRightOne(N9.self)

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
// Proved by: extension Zero: MultiplicationLeftOne + extension AddOne: MultiplicationLeftOne
// Each step adds one tick (Left = 1) and one group boundary.
func useMultiplicationLeftOne<N: MultiplicationLeftOne>(_: N.Type) {}
useMultiplicationLeftOne(N0.self)
useMultiplicationLeftOne(N5.self)
useMultiplicationLeftOne(N9.self)

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
// The reverse proof chains SuccessorLeftMultiplication from 0 * A = 0 up to b * A.

// Universality: the generic constraint accepts ANY chain AddOne^b(MultiplicationCommutativityOfTwoSeed)
func useMultiplicationCommutativityOfTwo<N: MultiplicationCommutativityOfTwo>(_: N.Type) {}
useMultiplicationCommutativityOfTwo(MultiplicationCommutativityOfTwoSeed.self)                                      // b = 0
useMultiplicationCommutativityOfTwo(AddOne<AddOne<AddOne<MultiplicationCommutativityOfTwoSeed>>>.self)              // b = 3

// Verify Totals match: 2 * 3 = 3 * 2 = 6
typealias MultiplicationCommutativity2Times3 = AddOne<AddOne<AddOne<MultiplicationCommutativityOfTwoSeed>>>
assertEqual(MultiplicationCommutativity2Times3.ForwardProof.Total.self, MultiplicationCommutativity2Times3.ReverseProof.Total.self)
assertEqual(MultiplicationCommutativity2Times3.ForwardProof.Total.self, N6.self)

// Verify Left/Right are correct:
assertEqual(MultiplicationCommutativity2Times3.ForwardProof.Left.self, N2.self)   // 2 * 3
assertEqual(MultiplicationCommutativity2Times3.ForwardProof.Right.self, N3.self)
assertEqual(MultiplicationCommutativity2Times3.ReverseProof.Left.self, N3.self)   // 3 * 2
assertEqual(MultiplicationCommutativity2Times3.ReverseProof.Right.self, N2.self)

// Similarly for N3: universality over all b
func useMultiplicationCommutativityOfThree<N: MultiplicationCommutativityOfThree>(_: N.Type) {}
useMultiplicationCommutativityOfThree(MultiplicationCommutativityOfThreeSeed.self)                                                // b = 0
useMultiplicationCommutativityOfThree(AddOne<AddOne<AddOne<AddOne<MultiplicationCommutativityOfThreeSeed>>>>.self)                // b = 4

// Verify Totals match: 3 * 4 = 4 * 3 = 12
typealias MultiplicationCommutativity3Times4 = AddOne<AddOne<AddOne<AddOne<MultiplicationCommutativityOfThreeSeed>>>>
assertEqual(MultiplicationCommutativity3Times4.ForwardProof.Total.self, MultiplicationCommutativity3Times4.ReverseProof.Total.self)
assertEqual(MultiplicationCommutativity3Times4.ForwardProof.Total.self, N12.self)

// Verify Left/Right are correct:
assertEqual(MultiplicationCommutativity3Times4.ForwardProof.Left.self, N3.self)   // 3 * 4
assertEqual(MultiplicationCommutativity3Times4.ForwardProof.Right.self, N4.self)
assertEqual(MultiplicationCommutativity3Times4.ReverseProof.Left.self, N4.self)   // 4 * 3
assertEqual(MultiplicationCommutativity3Times4.ReverseProof.Right.self, N3.self)

// -- Macro-generated commutativity proofs (N4, N5) --
// The @MultiplicationCommutativityProof macro generates bounded-depth paired proofs:
//   ForwardK witnesses A * K (flat encoding)
//   ReverseK witnesses K * A (via SuccessorLeftMultiplication.Distributed)
// The type checker verifies that both Total types are equal.

@MultiplicationCommutativityProof(leftOperand: 4, depth: 5)
enum MultiplicationCommutativity4 {}

@MultiplicationCommutativityProof(leftOperand: 5, depth: 4)
enum MultiplicationCommutativity5 {}

// N4: 4 * 3 = 3 * 4 = 12
assertEqual(MultiplicationCommutativity4.Forward3.Total.self, MultiplicationCommutativity4.Reverse3.Total.self)
assertEqual(MultiplicationCommutativity4.Forward3.Total.self, N12.self)
assertEqual(MultiplicationCommutativity4.Forward3.Left.self, N4.self)   // 4 * 3
assertEqual(MultiplicationCommutativity4.Forward3.Right.self, N3.self)
assertEqual(MultiplicationCommutativity4.Reverse3.Left.self, N3.self)   // 3 * 4
assertEqual(MultiplicationCommutativity4.Reverse3.Right.self, N4.self)

// N5: 5 * 2 = 2 * 5 = 10
assertEqual(MultiplicationCommutativity5.Forward2.Total.self, MultiplicationCommutativity5.Reverse2.Total.self)
assertEqual(MultiplicationCommutativity5.Forward2.Total.self, N10.self)
assertEqual(MultiplicationCommutativity5.Forward2.Left.self, N5.self)   // 5 * 2
assertEqual(MultiplicationCommutativity5.Forward2.Right.self, N2.self)
assertEqual(MultiplicationCommutativity5.Reverse2.Left.self, N2.self)   // 2 * 5
assertEqual(MultiplicationCommutativity5.Reverse2.Right.self, N5.self)

// MARK: - 11. Coinductive streams for irrational numbers
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
// convergent constructions. GCFConvergent0<B0> takes the first CF coefficient
// as its type parameter; for depth-0 convergents, h_0 = b_0.
//
// Golden ratio: PhiCF.Head = 1, matching the all-ones CF [1; 1, 1, ...]
assertEqual(PhiCF.Head.self, GoldenRatioProof.Convergent0.P.self)    // both N1
// Sqrt2: Sqrt2CF.Head = 1, matching [1; 2, 2, ...]
assertEqual(Sqrt2CF.Head.self, Sqrt2ConvergenceProof.Convergent0.P.self)         // both N1

// MARK: - 12. Distributivity of multiplication over addition
//
// Distributivity -- a * (b + c) = a*b + a*c -- bridges the sum and product
// witness systems. The flat encoding makes it natural: a * (b + c) has
// (b + c) groups of a ticks, which is b groups (the a*b part) followed by
// c groups (the a*c part).
//
// ProductSeed<Q> wraps an existing product proof Q (for a*b). TimesTick and
// TimesGroup layers on top represent a*c. The MultiplicationDistributive protocol
// tracks a NaturalSum witness through the product proof:
//   - ProductSeed<Q>: DistributiveSum = PlusZero<Q.Total>  (a*b + 0 = a*b)
//   - TimesTick:      DistributiveSum = PlusSucc<...>       (adds 1 to the sum)
//   - TimesGroup:     DistributiveSum unchanged             (group boundary)
//
// At the end, DistributiveSum witnesses a*b + a*c = a*(b+c).

// The generic constraint proves universality: every MultiplicationDistributive proof
// carries a DistributiveSum witnessing the distributive decomposition.
func useDistributivity<P: MultiplicationDistributive>(_: P.Type) {}

// Example 1: 2 * (1 + 1) = 2*1 + 2*1 = 2 + 2 = 4
// Start with FlatProduct2Times1 (2*1 = 2), add 1 group of 2 ticks.
typealias Distributive2Times1Plus1 = TimesGroup<TimesTick<TimesTick<ProductSeed<FlatProduct2Times1>>>>

assertEqual(Distributive2Times1Plus1.Left.self, N2.self)              // a = 2
assertEqual(Distributive2Times1Plus1.Right.self, N2.self)             // b + c = 1 + 1 = 2
assertEqual(Distributive2Times1Plus1.Total.self, N4.self)             // 2 * 2 = 4

assertEqual(Distributive2Times1Plus1.DistributiveSum.Left.self, N2.self)     // a*b = 2*1 = 2
assertEqual(Distributive2Times1Plus1.DistributiveSum.Right.self, N2.self)    // a*c = 2*1 = 2
assertEqual(Distributive2Times1Plus1.DistributiveSum.Total.self, N4.self)    // 2 + 2 = 4

useDistributivity(Distributive2Times1Plus1.self)

// Example 2: 3 * (2 + 1) = 3*2 + 3*1 = 6 + 3 = 9
// Define flat proofs for 3*0, 3*1, 3*2 (3 ticks per group).
typealias FlatProduct3Times0 = TimesZero<N3>
typealias FlatProduct3Times1 = TimesGroup<TimesTick<TimesTick<TimesTick<FlatProduct3Times0>>>>
typealias FlatProduct3Times2 = TimesGroup<TimesTick<TimesTick<TimesTick<FlatProduct3Times1>>>>

assertEqual(FlatProduct3Times2.Left.self, N3.self)
assertEqual(FlatProduct3Times2.Right.self, N2.self)
assertEqual(FlatProduct3Times2.Total.self, N6.self)             // 3 * 2 = 6

// Stack 1 group of 3 ticks on ProductSeed<FlatProduct3Times2>.
typealias Distributive3Times2Plus1 = TimesGroup<TimesTick<TimesTick<TimesTick<ProductSeed<FlatProduct3Times2>>>>>

assertEqual(Distributive3Times2Plus1.Left.self, N3.self)              // a = 3
assertEqual(Distributive3Times2Plus1.Right.self, N3.self)             // b + c = 2 + 1 = 3
assertEqual(Distributive3Times2Plus1.Total.self, N9.self)             // 3 * 3 = 9

assertEqual(Distributive3Times2Plus1.DistributiveSum.Left.self, N6.self)     // a*b = 3*2 = 6
assertEqual(Distributive3Times2Plus1.DistributiveSum.Right.self, N3.self)    // a*c = 3*1 = 3
assertEqual(Distributive3Times2Plus1.DistributiveSum.Total.self, N9.self)    // 6 + 3 = 9

useDistributivity(Distributive3Times2Plus1.self)

// Example 3: 2 * (2 + 3) = 2*2 + 2*3 = 4 + 6 = 10
// Stack 3 groups of 2 ticks on ProductSeed<FlatProduct2Times2>.
typealias Distributive2Times2Plus3 = TimesGroup<TimesTick<TimesTick<
                          TimesGroup<TimesTick<TimesTick<
                            TimesGroup<TimesTick<TimesTick<
                              ProductSeed<FlatProduct2Times2>>>>>>>>>>

assertEqual(Distributive2Times2Plus3.Left.self, N2.self)              // a = 2
assertEqual(Distributive2Times2Plus3.Right.self, N5.self)             // b + c = 2 + 3 = 5
assertEqual(Distributive2Times2Plus3.Total.self, N10.self)            // 2 * 5 = 10

assertEqual(Distributive2Times2Plus3.DistributiveSum.Left.self, N4.self)     // a*b = 2*2 = 4
assertEqual(Distributive2Times2Plus3.DistributiveSum.Right.self, N6.self)    // a*c = 2*3 = 6
assertEqual(Distributive2Times2Plus3.DistributiveSum.Total.self, N10.self)   // 4 + 6 = 10

useDistributivity(Distributive2Times2Plus3.self)

// MARK: - 13. Number-theoretic identities
//
// Distributivity and SuccessorLeftMultiplication combine to prove algebraic identities that
// explain WHY numerical correspondences hold, not just THAT they hold.
//
// Difference of squares: n*(n+2) + 1 = (n+1)^2
// Both sides decompose via a shared base n*(n+1):
//   (n+1)^2     = n*(n+1) + (n+1)    [SuccessorLeftMultiplication]
//   n*(n+2)     = n*((n+1)+1) = n*(n+1) + n  [distributivity + MultiplicationRightOne]
//   Difference  = (n+1) - n = 1
//
// Cassini identity: F(n-1)*F(n+1) - F(n)^2 = (-1)^n
// The key step uses distributivity:
//   F(n+1)*F(n-1) = (F(n)+F(n-1))*F(n-1) = F(n)*F(n-1) + F(n-1)^2
// This relates the cross-product at step n to the square and cross-product
// at step n-1. The two identities are connected: Cassini at odd n IS
// difference-of-squares for appropriate values of n.

// -- Auxiliary flat proofs for Left=1 --
typealias FlatProduct1Times0 = TimesZero<N1>
typealias FlatProduct1Times1 = TimesGroup<TimesTick<FlatProduct1Times0>>
typealias FlatProduct1Times2 = TimesGroup<TimesTick<FlatProduct1Times1>>
assertEqual(FlatProduct1Times2.Total.self, N2.self)                      // 1 * 2 = 2

// -- Difference of squares, n = 1: 1*3 + 1 = 4 = 2^2 --
// Shared base: 1*2 = 2 (FlatProduct1Times2)
// SuccessorLeftMultiplication: 1*2 = 2 => 2*2 = 2 + 2 = 4
assertEqual(FlatProduct1Times2.Distributed.Left.self, N2.self)
assertEqual(FlatProduct1Times2.Distributed.Right.self, N2.self)
assertEqual(FlatProduct1Times2.Distributed.Total.self, N4.self)          // 2*2 = 4

// Distributivity: 1*(2+1) = 1*2 + 1*1 = 2 + 1 = 3
typealias Distributive1Times2Plus1 = TimesGroup<TimesTick<ProductSeed<FlatProduct1Times2>>>
assertEqual(Distributive1Times2Plus1.Total.self, N3.self)                      // 1*3 = 3
assertEqual(Distributive1Times2Plus1.DistributiveSum.Left.self, N2.self)              // 1*2 = 2
assertEqual(Distributive1Times2Plus1.DistributiveSum.Right.self, N1.self)             // 1*1 = 1
assertEqual(Distributive1Times2Plus1.DistributiveSum.Total.self, N3.self)             // 2 + 1 = 3

// The identity: 1*3 + 1 = 4 = 2*2
typealias DifferenceOfSquares1 = PlusSucc<PlusZero<N3>>                       // 3 + 1 = 4
assertEqual(DifferenceOfSquares1.Total.self, FlatProduct1Times2.Distributed.Total.self)  // 4 = 4

// -- Difference of squares, n = 2: 2*4 + 1 = 9 = 3^2 --
// Shared base: 2*3 = 6 (FlatProduct2Times3 from section 10)
// SuccessorLeftMultiplication: 2*3 = 6 => 3*3 = 6 + 3 = 9 (verified in section 10)
// Distributivity: 2*(3+1) = 2*3 + 2*1 = 6 + 2 = 8
typealias Distributive2Times3Plus1 = TimesGroup<TimesTick<TimesTick<ProductSeed<FlatProduct2Times3>>>>
assertEqual(Distributive2Times3Plus1.Total.self, N8.self)                      // 2*4 = 8
assertEqual(Distributive2Times3Plus1.DistributiveSum.Left.self, N6.self)              // 2*3 = 6
assertEqual(Distributive2Times3Plus1.DistributiveSum.Right.self, N2.self)             // 2*1 = 2
assertEqual(Distributive2Times3Plus1.DistributiveSum.Total.self, N8.self)             // 6 + 2 = 8

// The identity: 2*4 + 1 = 9 = 3*3
typealias DifferenceOfSquares2 = PlusSucc<PlusZero<N8>>                       // 8 + 1 = 9
assertEqual(DifferenceOfSquares2.Total.self, FlatProduct2Times3.Distributed.Total.self)  // 9 = 9

// -- Cassini n = 2 (even): F(1)*F(3) = F(2)^2 + 1 --
// F(1)=1, F(2)=1, F(3)=2.  1*2 = 1*1 + 1 => 2 = 1 + 1

// F(2)^2 = 1*1 = 1 (MultiplicationRightOne)
assertEqual(N1.TimesOneProof.Total.self, N1.self)                 // 1*1 = 1

// F(1)*F(3) = 1*2 = 2 (MultiplicationLeftOne)
assertEqual(N2.OneTimesProof.Total.self, N2.self)                 // 1*2 = 2

// 1 + 1 = 2
typealias Cassini2 = PlusSucc<PlusZero<N1>>
assertEqual(Cassini2.Total.self, N2.OneTimesProof.Total.self)     // F(2)^2 + 1 = F(1)*F(3)

// -- Cassini n = 3 (odd): F(2)*F(4) + 1 = F(3)^2 --
// F(2)=1, F(3)=2, F(4)=3.  1*3 + 1 = 4 = 2*2
// This IS diff-of-squares n=1: DifferenceOfSquares1 proves 3 + 1 = 4 = 2^2.
// Distributive1Times2Plus1 decomposes F(4)*F(2) = (F(3)+F(2))*F(2) = F(3)*F(2) + F(2)^2.

// -- Cassini n = 4 (even): F(3)*F(5) = F(4)^2 + 1 --
// F(3)=2, F(4)=3, F(5)=5.  2*5 = 9 + 1 = 10
//
// F(4)^2 = 3*3 = 9 (FlatProduct2Times3.Distributed from section 10)
// Distributive decomposition via Distributive2Times2Plus3 from section 12:
//   F(5)*F(3) = (F(4)+F(3))*F(3) = F(4)*F(3) + F(3)^2 = 6 + 4 = 10

// F(3)*F(5) = 2*5 = 10
typealias FlatProduct2Times4 = TimesGroup<TimesTick<TimesTick<FlatProduct2Times3>>>
typealias FlatProduct2Times5 = TimesGroup<TimesTick<TimesTick<FlatProduct2Times4>>>
assertEqual(FlatProduct2Times5.Total.self, N10.self)                      // 2*5 = 10

// F(4)^2 + 1 = F(3)*F(5): 9 + 1 = 10
typealias Cassini4 = PlusSucc<PlusZero<N9>>
assertEqual(Cassini4.Total.self, FlatProduct2Times5.Total.self)           // 9 + 1 = 10 = 2*5

// MARK: - 14. CF convergent determinant identity for sqrt(2)
//
// The convergent determinant identity is a structural invariant of continued
// fractions: h_n * k_{n-1} - h_{n-1} * k_n = (-1)^{n+1}
//
// In naturals (avoiding subtraction), this becomes:
//   Odd n:  h_n * k_{n-1} = h_{n-1} * k_n + 1
//   Even n: h_{n-1} * k_n = h_n * k_{n-1} + 1
//
// For the golden ratio, this reduces to the Cassini identity (section 13).
// For sqrt(2), with convergents h_0/k_0 = 1/1, h_1/k_1 = 3/2, h_2/k_2 = 7/5:

// -- n = 1 (odd, determinant = +1): h_1*k_0 = h_0*k_1 + 1 => 3*1 = 1*2 + 1 => 3 = 3 --
//
// h_1*k_0 = 3*1: chain SuccessorLeftMultiplication from 1*1 = 1
typealias Sqrt2Determinant3Times1 = N1.OneTimesProof.Distributed.Distributed
assertEqual(Sqrt2Determinant3Times1.Left.self, N3.self)                        // h_1 = 3
assertEqual(Sqrt2Determinant3Times1.Right.self, N1.self)                       // k_0 = 1
assertEqual(Sqrt2Determinant3Times1.Total.self, N3.self)                       // 3*1 = 3

// h_0*k_1 = 1*2
typealias Sqrt2Determinant1Times2 = N2.OneTimesProof
assertEqual(Sqrt2Determinant1Times2.Left.self, N1.self)                        // h_0 = 1
assertEqual(Sqrt2Determinant1Times2.Right.self, N2.self)                       // k_1 = 2
assertEqual(Sqrt2Determinant1Times2.Total.self, N2.self)                       // 1*2 = 2

// The identity: h_0*k_1 + 1 = h_1*k_0
typealias Sqrt2DeterminantWitness1 = PlusSucc<PlusZero<N2>>                     // 2 + 1 = 3
assertEqual(Sqrt2DeterminantWitness1.Total.self, Sqrt2Determinant3Times1.Total.self)       // 3 = 3

// Connect to macro-generated convergents:
assertEqual(Sqrt2Determinant3Times1.Left.self, Sqrt2ConvergenceProof.Convergent1.P.self)         // h_1 = 3
assertEqual(Sqrt2Determinant1Times2.Right.self, Sqrt2ConvergenceProof.Convergent1.Q.self)        // k_1 = 2

// -- n = 2 (even, determinant = -1): h_1*k_2 = h_2*k_1 + 1 => 3*5 = 7*2 + 1 => 15 = 15 --
//
// h_1*k_2 = 3*5: chain SuccessorLeftMultiplication from 1*5 = 5
typealias Sqrt2Determinant3Times5 = N5.OneTimesProof.Distributed.Distributed
assertEqual(Sqrt2Determinant3Times5.Left.self, N3.self)                        // h_1 = 3
assertEqual(Sqrt2Determinant3Times5.Right.self, N5.self)                       // k_2 = 5
assertEqual(Sqrt2Determinant3Times5.Total.self, N15.self)                      // 3*5 = 15

// h_2*k_1 = 7*2: chain SuccessorLeftMultiplication from 1*2 = 2 through 6 Distributed steps
typealias Sqrt2Determinant7Times2 = Sqrt2Determinant1Times2.Distributed.Distributed.Distributed.Distributed.Distributed.Distributed
assertEqual(Sqrt2Determinant7Times2.Left.self, N7.self)                        // h_2 = 7
assertEqual(Sqrt2Determinant7Times2.Right.self, N2.self)                       // k_1 = 2
assertEqual(Sqrt2Determinant7Times2.Total.self, AddOne<N13>.self)              // 7*2 = 14

// The identity: h_2*k_1 + 1 = h_1*k_2
typealias Sqrt2DeterminantWitness2 = PlusSucc<PlusZero<AddOne<N13>>>            // 14 + 1 = 15
assertEqual(Sqrt2DeterminantWitness2.Total.self, Sqrt2Determinant3Times5.Total.self)       // 15 = 15

// Connect to macro-generated convergents:
assertEqual(Sqrt2Determinant3Times5.Right.self, Sqrt2ConvergenceProof.Convergent2.Q.self)        // k_2 = 5
assertEqual(Sqrt2Determinant7Times2.Left.self, Sqrt2ConvergenceProof.Convergent2.P.self)         // h_2 = 7

// MARK: - 15. Wallis-Leibniz denominator correspondence
//
// The codebase proves three pi constructions independently:
//   Brouncker CF (convergents h_k/k_k), Leibniz series (partial sums S_k),
//   and the Wallis product (partial products W_k).
//
// The missing link: each Wallis denominator equals the product of two
// consecutive Leibniz denominators.
//
//   WQ[k] = LQ[k+1] * LQ[k]
//
// Leibniz denominators accumulate one odd factor per step (1, 3, 15, 105, ...),
// while Wallis denominators accumulate paired odd factors ((2k-1)(2k+1)).
// The product of consecutive Leibniz denominators telescopes into the Wallis
// denominator.

// -- k=1: WQ[1] = LQ[2] * LQ[1] = 3 * 1 = 3 --

typealias WallisLeibnizProduct3Times1 = N3.TimesOneProof
assertEqual(WallisLeibnizProduct3Times1.Left.self, PiConvergenceProof.LeibnizSum2.Q.self)      // 3 = 3
assertEqual(WallisLeibnizProduct3Times1.Right.self, PiConvergenceProof.LeibnizSum1.Q.self)     // 1 = 1
assertEqual(WallisLeibnizProduct3Times1.Total.self, WallisProductProof.Wallis1.Q.self)  // 3 = 3

// -- Bonus: W_1 = 2 * S_2 (as fractions: 4/3 = 2 * (2/3)) --
//
// Numerator: 4 = 2 * 2. Use SuccessorLeftMultiplication: 1*2 = 2 (OneTimesProof), then
// S(1)*2 = 2 + 2 = 4 via Distributed.
typealias WallisLeibnizProduct2TimesLeibniz2P = N2.OneTimesProof.Distributed
assertEqual(WallisLeibnizProduct2TimesLeibniz2P.Total.self, WallisProductProof.Wallis1.P.self)  // 4 = 4
// Denominator: trivially equal (both are 3).
assertEqual(WallisProductProof.Wallis1.Q.self, PiConvergenceProof.LeibnizSum2.Q.self)              // 3 = 3

// -- k=2: WQ[2] = LQ[3] * LQ[2] = 15 * 3 = 45 --
//
// Chain SuccessorLeftMultiplication from 1*3 = 3 (OneTimesProof) through 14 Distributed steps.
// Intermediate milestones: 5*3=15, 10*3=30, 15*3=45.
typealias WallisLeibnizChain1Times3 = N3.OneTimesProof                                                                // 1*3 = 3
typealias WallisLeibnizChain5Times3 = WallisLeibnizChain1Times3.Distributed.Distributed.Distributed.Distributed                          // 5*3 = 15
typealias WallisLeibnizChain10Times3 = WallisLeibnizChain5Times3.Distributed.Distributed.Distributed.Distributed.Distributed             // 10*3 = 30
typealias WallisLeibnizChain15Times3 = WallisLeibnizChain10Times3.Distributed.Distributed.Distributed.Distributed.Distributed            // 15*3 = 45

assertEqual(WallisLeibnizChain15Times3.Left.self, PiConvergenceProof.LeibnizSum3.Q.self)      // 15 = 15
assertEqual(WallisLeibnizChain15Times3.Right.self, PiConvergenceProof.LeibnizSum2.Q.self)     // 3 = 3
assertEqual(WallisLeibnizChain15Times3.Total.self, WallisProductProof.Wallis2.Q.self)  // 45 = 45

// -- Three-way connection via Brouncker CF --
//
// The Brouncker-Leibniz correspondence (proved by the macro) gives CF_k.P = LS_{k+1}.Q.
// So WQ[k] = CF_k.P * CF_{k-1}.P as well.
assertEqual(PiConvergenceProof.Convergent1.P.self, PiConvergenceProof.LeibnizSum2.Q.self)    // 3 = 3 (Brouncker-Leibniz at k=1)
assertEqual(PiConvergenceProof.Convergent0.P.self, PiConvergenceProof.LeibnizSum1.Q.self)    // 1 = 1 (Brouncker-Leibniz at k=0)
assertEqual(PiConvergenceProof.Convergent2.P.self, PiConvergenceProof.LeibnizSum3.Q.self)    // 15 = 15 (Brouncker-Leibniz at k=2)

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
// addition), number-theoretic identities (difference-of-squares, Cassini
// identity for Fibonacci, CF convergent determinant identity for sqrt(2)),
// the Wallis-Leibniz denominator correspondence (connecting all three pi
// representations), and coinductive streams for irrational numbers (PhiCF,
// Sqrt2CF with universal unfold theorems) -- all without executing a
// single computation at runtime.
