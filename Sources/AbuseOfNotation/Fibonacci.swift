// MARK: - Fibonacci verification infrastructure

/// State of a Fibonacci computation: tracks three consecutive values.
public protocol FibonacciState {
    associatedtype Current: Natural
    associatedtype Prev: Natural
    associatedtype Next: Natural
}

/// A FibonacciState whose recurrence is witnessed by a NaturalSum proof.
///
/// The where clause on SumWitness forces `Next == Prev + Current`,
/// encoding the Fibonacci recurrence relation as a type-level constraint.
/// Any type conforming to FibonacciVerified must carry a NaturalSum witness
/// proving that its three values satisfy the recurrence.
public protocol FibonacciVerified: FibonacciState {
    associatedtype SumWitness: NaturalSum
        where SumWitness.Left == Prev,
              SumWitness.Right == Current,
              Next == SumWitness.Total
}

/// Base case: F(0) = 0, with Prev = 1 and Next = 1.
///
/// The witness PlusZero<N1> proves 1 + 0 = 1 (Prev + Current = Next).
public struct Fibonacci0: FibonacciVerified {
    public typealias Prev = AddOne<Zero>
    public typealias Current = Zero
    public typealias Next = AddOne<Zero>
    public typealias SumWitness = PlusZero<AddOne<Zero>>
}

/// Inductive step: given a verified state S and a sum witness W proving
/// S.Current + S.Next = W.Total, produce the next verified state.
///
/// The where clause `W.Left == S.Current, W.Right == S.Next` ensures
/// the witness matches the previous state's values. FibonacciVerified's
/// constraint then verifies the new state's recurrence.
public struct FibonacciStep<S: FibonacciVerified, W: NaturalSum>: FibonacciVerified
    where W.Left == S.Current, W.Right == S.Next
{
    public typealias Prev = S.Current
    public typealias Current = S.Next
    public typealias Next = W.Total
    public typealias SumWitness = W
}
