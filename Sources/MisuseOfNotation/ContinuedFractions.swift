// MARK: - Type-level fraction

/// Type-level rational number: Numerator / Denominator.
/// Purely structural -- encodes the pair without computing.
public enum Fraction<Numerator: Natural, Denominator: Natural> {}

// MARK: - Generalized continued fraction convergent

/// State of a generalized continued fraction convergent at depth n.
/// P/Q is the current convergent h_n/k_n; PrevP/PrevQ is h_{n-1}/k_{n-1}.
///
/// The recurrence for the standard continued fraction:
///   h_n = b_n * h_{n-1} + a_n * h_{n-2}
///   k_n = b_n * k_{n-1} + a_n * k_{n-2}
public protocol GCFConvergent {
    associatedtype P: Natural      // h_n (numerator)
    associatedtype Q: Natural      // k_n (denominator)
    associatedtype PrevP: Natural  // h_{n-1}
    associatedtype PrevQ: Natural  // k_{n-1}
}

/// Base convergent (depth 0): h_0 = b_0, k_0 = 1, with h_{-1} = 1, k_{-1} = 0.
public struct GCFConvergent0<B0: Natural>: GCFConvergent {
    public typealias P = B0
    public typealias Q = AddOne<Zero>
    public typealias PrevP = AddOne<Zero>
    public typealias PrevQ = Zero
}

/// Step convergent: h_n = b * h_{n-1} + a * h_{n-2}, k_n = b * k_{n-1} + a * k_{n-2}.
///
/// Takes the previous convergent plus witnesses for the six arithmetic operations:
///   BTimesP:    b * h_{n-1}
///   ATimesPrevP: a * h_{n-2}
///   PResult:    b*h_{n-1} + a*h_{n-2} = h_n
///   BTimesQ:    b * k_{n-1}
///   ATimesPrevQ: a * k_{n-2}
///   QResult:    b*k_{n-1} + a*k_{n-2} = k_n
public struct GCFConvergentStep<
    Prev: GCFConvergent,
    BTimesP: NaturalProduct,
    ATimesPrevP: NaturalProduct,
    PResult: NaturalSum,
    BTimesQ: NaturalProduct,
    ATimesPrevQ: NaturalProduct,
    QResult: NaturalSum
>: GCFConvergent
where
    BTimesP.Right == Prev.P,
    ATimesPrevP.Right == Prev.PrevP,
    PResult.Left == BTimesP.Total, PResult.Right == ATimesPrevP.Total,
    BTimesQ.Right == Prev.Q,
    ATimesPrevQ.Right == Prev.PrevQ,
    QResult.Left == BTimesQ.Total, QResult.Right == ATimesPrevQ.Total,
    BTimesP.Left == BTimesQ.Left,         // same b
    ATimesPrevP.Left == ATimesPrevQ.Left  // same a
{
    public typealias P = PResult.Total
    public typealias Q = QResult.Total
    public typealias PrevP = Prev.P
    public typealias PrevQ = Prev.Q
}

// MARK: - Leibniz series partial sum

/// State of the Leibniz series pi/4 = 1 - 1/3 + 1/5 - ... after n terms.
/// P/Q is the partial sum as a fraction.
public protocol LeibnizPartialSum {
    associatedtype P: Natural  // numerator
    associatedtype Q: Natural  // denominator
}

/// S_1 = 1/1 (the first term of the Leibniz series).
public struct LeibnizBase: LeibnizPartialSum {
    public typealias P = AddOne<Zero>
    public typealias Q = AddOne<Zero>
}

/// Subtraction step: if prev = p/q, then this computes (p*d - q) / (q*d)
/// where d is the next odd denominator. Subtraction is witnessed by a
/// NaturalSum proving that Result + q = p*d (i.e. p*d - q = Result).
///
/// Used for the minus terms in the alternating Leibniz series.
public struct LeibnizSub<
    Prev: LeibnizPartialSum,
    PTimesD: NaturalProduct,
    QTimesD: NaturalProduct,
    SubWitness: NaturalSum
>: LeibnizPartialSum
where
    PTimesD.Left == Prev.P,
    QTimesD.Left == Prev.Q,
    PTimesD.Right == QTimesD.Right,        // same d
    SubWitness.Total == PTimesD.Total,     // result + q = p*d
    SubWitness.Right == Prev.Q             // subtracting q
{
    public typealias P = SubWitness.Left   // p*d - q
    public typealias Q = QTimesD.Total     // q*d
}

/// Addition step: if prev = p/q, then this computes (p*d + q) / (q*d)
/// where d is the next odd denominator. Addition is witnessed by a NaturalSum.
///
/// Used for the plus terms in the alternating Leibniz series.
public struct LeibnizAdd<
    Prev: LeibnizPartialSum,
    PTimesD: NaturalProduct,
    QTimesD: NaturalProduct,
    AddWitness: NaturalSum
>: LeibnizPartialSum
where
    PTimesD.Left == Prev.P,
    QTimesD.Left == Prev.Q,
    PTimesD.Right == QTimesD.Right,        // same d
    AddWitness.Left == PTimesD.Total,      // p*d + q
    AddWitness.Right == Prev.Q
{
    public typealias P = AddWitness.Total  // p*d + q
    public typealias Q = QTimesD.Total     // q*d
}

// MARK: - Wallis product partial product

/// State of the Wallis product pi/2 = prod_{k=1}^{inf} (2k)^2 / ((2k-1)(2k+1))
/// after k steps. P/Q is the unreduced partial product numerator/denominator.
public protocol WallisPartialProduct {
    associatedtype P: Natural  // numerator
    associatedtype Q: Natural  // denominator
}

/// W_0 = 1/1 (empty product).
public struct WallisBase: WallisPartialProduct {
    public typealias P = AddOne<Zero>
    public typealias Q = AddOne<Zero>
}

/// Wallis step: multiply numerator by (2k)^2 and denominator by (2k-1)(2k+1).
///
/// Two-step product decomposition to keep factor sizes manageable:
///   Numerator:   prev_p * 2k = mid_p, then mid_p * 2k = new_p
///   Denominator: prev_q * (2k-1) = mid_q, then mid_q * (2k+1) = new_q
///
/// The `PTimesTwoK.Right == MidPTimesTwoK.Right` constraint ensures
/// both numerator multiplications use the same factor 2k.
public struct WallisStep<
    Prev: WallisPartialProduct,
    PTimesTwoK: NaturalProduct,
    MidPTimesTwoK: NaturalProduct,
    QTimesTwoKm1: NaturalProduct,
    MidQTimesTwoKp1: NaturalProduct
>: WallisPartialProduct
where
    PTimesTwoK.Left == Prev.P,               // prev_p * 2k
    MidPTimesTwoK.Left == PTimesTwoK.Total,   // (prev_p * 2k) * 2k
    PTimesTwoK.Right == MidPTimesTwoK.Right,  // same 2k
    QTimesTwoKm1.Left == Prev.Q,              // prev_q * (2k-1)
    MidQTimesTwoKp1.Left == QTimesTwoKm1.Total // (prev_q * (2k-1)) * (2k+1)
{
    public typealias P = MidPTimesTwoK.Total   // prev_p * (2k)^2
    public typealias Q = MidQTimesTwoKp1.Total // prev_q * (2k-1)(2k+1)
}

// MARK: - 2x2 matrix (type-level)

/// A 2x2 matrix of natural numbers, encoded as four associated types.
/// Used to represent the matrix product form of CF convergents.
public protocol Matrix2x2 {
    associatedtype A: Natural  // top-left
    associatedtype B: Natural  // top-right
    associatedtype C: Natural  // bottom-left
    associatedtype D: Natural  // bottom-right
}

/// Concrete 2x2 matrix type.
public struct Matrix2<TopLeft: Natural, TopRight: Natural,
                   BottomLeft: Natural, BottomRight: Natural>: Matrix2x2 {
    public typealias A = TopLeft
    public typealias B = TopRight
    public typealias C = BottomLeft
    public typealias D = BottomRight
}

/// Left-multiplication by a 2x2 CF matrix (type-level matrix step).
///
/// Given Prev = [[a,b],[c,d]], produces [[f*a+c, f*b+d], [a, b]]
/// where f is the shared Left of both product witnesses.
/// The bottom row copies from the previous top row -- no arithmetic needed.
/// Only 2 products + 2 sums per step.
///
/// For sqrt(2) CF, f=2 (the macro supplies TimesSucc witnesses with Left=N2).
/// The relational constraint `FTimesA.Left == FTimesB.Left` ensures both
/// products use the same factor without pinning to a concrete type, avoiding
/// the Swift compiler's generic rewrite system complexity limit.
public struct Sqrt2MatStep<
    Prev: Matrix2x2,
    FTimesA: NaturalProduct,
    SumAC: NaturalSum,
    FTimesB: NaturalProduct,
    SumBD: NaturalSum
>: Matrix2x2
where
    FTimesA.Left == FTimesB.Left,       // same factor f
    FTimesA.Right == Prev.A,
    SumAC.Left == FTimesA.Total,
    SumAC.Right == Prev.C,
    FTimesB.Right == Prev.B,
    SumBD.Left == FTimesB.Total,
    SumBD.Right == Prev.D
{
    public typealias A = SumAC.Total    // f*a + c
    public typealias B = SumBD.Total    // f*b + d
    public typealias C = Prev.A         // a (drops down)
    public typealias D = Prev.B         // b (drops down)
}
