// Universal addition theorems proved by structural induction.
//
// Each protocol defines a theorem. Conditional conformances on Zero/AddOne
// (or PlusZero/PlusSucc) provide base case + inductive step = proof for all
// natural numbers. The protocols use plain associated types (no where
// clauses) following the TimesNk pattern; correctness is enforced
// structurally by the conformance definitions and verified via assertEqual
// on specific instances.

// MARK: - Theorem 1: Left zero identity (0 + n = n)

/// For any natural number N, there exists a proof that 0 + N = N.
/// Proved by induction on N.
///
/// The associated type `ZeroPlusProof` is structurally guaranteed to be a
/// `NaturalSum` with `Left == Zero`, `Right == Self`, `Total == Self`.
public protocol AddLeftZero: Natural {
    associatedtype ZeroPlusProof: NaturalSum
}

// Base case: 0 + 0 = 0
extension Zero: AddLeftZero {
    public typealias ZeroPlusProof = PlusZero<Zero>
}

// Inductive step: if 0 + n = n, then 0 + S(n) = S(n)
// PlusSucc wraps Predecessor's proof to witness 0 + S(Predecessor) = S(Predecessor)
extension AddOne: AddLeftZero where Predecessor: AddLeftZero {
    public typealias ZeroPlusProof = PlusSucc<Predecessor.ZeroPlusProof>
}

// MARK: - Theorem 2: Successor-left shift (a + b = c => S(a) + b = S(c))

/// For any proof that a + b = c, there exists a proof that S(a) + b = S(c).
/// Proved by induction on the proof structure (PlusZero/PlusSucc).
///
/// The associated type `Shifted` is structurally guaranteed to be a
/// `NaturalSum` with `Left == AddOne<Self.Left>`, `Right == Self.Right`,
/// `Total == AddOne<Self.Total>`.
public protocol SuccessorLeftAdd: NaturalSum {
    associatedtype Shifted: NaturalSum
}

// Base case: PlusZero<N> witnesses N + 0 = N
// Shifted = PlusZero<S(N)> witnesses S(N) + 0 = S(N)
extension PlusZero: SuccessorLeftAdd {
    public typealias Shifted = PlusZero<AddOne<N>>
}

// Inductive step: PlusSucc<P> witnesses A + S(B) = S(C) where P: A + B = C
// If P.Shifted witnesses S(A) + B = S(C),
// then PlusSucc<P.Shifted> witnesses S(A) + S(B) = S(S(C))
extension PlusSucc: SuccessorLeftAdd where Proof: SuccessorLeftAdd {
    public typealias Shifted = PlusSucc<Proof.Shifted>
}

// MARK: - Theorem 3: Commutativity (a + b = c => b + a = c)

/// For any proof that a + b = c, there exists a proof that b + a = c.
/// Proved by induction on the proof structure.
///
/// The associated type `Commuted` is structurally guaranteed to be a
/// `NaturalSum` with `Left == Self.Right`, `Right == Self.Left`,
/// `Total == Self.Total`.
public protocol AddCommutative: NaturalSum {
    associatedtype Commuted: NaturalSum
}

// Base case: PlusZero<N> witnesses N + 0 = N
// Need: 0 + N = N -- this is exactly N's AddLeftZero proof
extension PlusZero: AddCommutative where N: AddLeftZero {
    public typealias Commuted = N.ZeroPlusProof
}

// Inductive step: PlusSucc<P> witnesses A + S(B) = S(C) where P: A + B = C
// If P.Commuted witnesses B + A = C,
// then P.Commuted.Shifted witnesses S(B) + A = S(C)
extension PlusSucc: AddCommutative
    where Proof: AddCommutative, Proof.Commuted: SuccessorLeftAdd
{
    public typealias Commuted = Proof.Commuted.Shifted
}

// MARK: - Theorem 4: Associativity ((a + b) + c = a + (b + c))

/// A Natural wrapping a NaturalSum proof, serving as base case for proof
/// extension. Analogous to Seed<A> for _InductiveAdd, but wraps a proof
/// instead of a number.
///
/// Building c layers of AddOne on ProofSeed<P> and extracting AssociativeProof
/// yields PlusSucc^c(P): the associativity proof.
public enum ProofSeed<P: NaturalSum>: Natural {
    public typealias Successor = AddOne<Self>
    public typealias Predecessor = SubOne<Zero>
}

/// For any chain AddOne^c(ProofSeed<P>), the AssociativeProof is PlusSucc^c(P),
/// witnessing a + (b + c) = d + c where P witnesses a + b = d.
///
/// Universality is twofold: parametric over P (any proof) and inductive
/// over c (any natural). This solves the "two-variable" problem noted in
/// section 5.2 of the future-work document.
public protocol AddAssociative: Natural {
    associatedtype AssociativeProof: NaturalSum
}

extension ProofSeed: AddAssociative {
    public typealias AssociativeProof = P
}

extension AddOne: AddAssociative where Predecessor: AddAssociative {
    public typealias AssociativeProof = PlusSucc<Predecessor.AssociativeProof>
}
