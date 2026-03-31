// MARK: - Sum

/// Witness that Left + Right = Total.
public protocol NaturalSum {
    associatedtype Left: Natural
    associatedtype Right: Natural
    associatedtype Total: Natural
}

/// N + 0 = N
public struct PlusZero<N: Natural>: NaturalSum {
    public typealias Left = N
    public typealias Right = Zero
    public typealias Total = N
}

/// If A + B = C, then A + S(B) = S(C)
public struct PlusSucc<Proof: NaturalSum>: NaturalSum {
    public typealias Left = Proof.Left
    public typealias Right = AddOne<Proof.Right>
    public typealias Total = AddOne<Proof.Total>
}

// MARK: - Product

/// Witness that Left * Right = Total.
public protocol NaturalProduct {
    associatedtype Left: Natural
    associatedtype Right: Natural
    associatedtype Total: Natural
}

/// N * 0 = 0
public struct TimesZero<N: Natural>: NaturalProduct {
    public typealias Left = N
    public typealias Right = Zero
    public typealias Total = Zero
}

/// If A * B = C and C + A = D, then A * S(B) = D
public struct TimesSucc<
    MulProof: NaturalProduct,
    AddProof: NaturalSum
>: NaturalProduct
    where AddProof.Left == MulProof.Total,
          AddProof.Right == MulProof.Left
{
    public typealias Left = MulProof.Left
    public typealias Right = AddOne<MulProof.Right>
    public typealias Total = AddProof.Total
}

// MARK: - Comparison

/// Witness that Left < Right.
public protocol NaturalLessThan {
    associatedtype Left: Natural
    associatedtype Right: Natural
}

/// 0 < S(N)
public struct ZeroLT<N: Natural>: NaturalLessThan {
    public typealias Left = Zero
    public typealias Right = AddOne<N>
}

/// If A < B, then S(A) < S(B)
public struct SuccLT<Proof: NaturalLessThan>: NaturalLessThan
    where Proof.Left: Natural
{
    public typealias Left = AddOne<Proof.Left>
    public typealias Right = AddOne<Proof.Right>
}
