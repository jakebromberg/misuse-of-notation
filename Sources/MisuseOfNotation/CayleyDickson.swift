// MARK: - Algebra protocol

/// Marker protocol for types in the Cayley-Dickson algebra hierarchy.
///
/// The Cayley-Dickson construction builds higher-dimensional algebras from pairs:
///   Level 0: Integers (scalars)
///   Level 1: Gaussian integers (complex integers: a + bi)
///   Level 2: Quaternions (a + bi + cj + dk)
///   Level 3: Octonions (8 dimensions)
///   Level n+1: Pairs of level-n elements, recursively
///
/// Each level doubles the dimension. Algebraic properties are progressively lost:
/// commutativity at quaternions (level 2), associativity at octonions (level 3).
///
/// Integer types conform as level-0 scalars; `CayleyDickson` pairs as level n+1.
public protocol Algebra {}

// MARK: - CayleyDickson type (type-level representation)

/// Cayley-Dickson pair at the type level: represents `(Re, Im)`.
///
/// Examples:
///   `CayleyDickson<AddOne<Zero>, AddOne<AddOne<Zero>>>` represents `1 + 2i`
///   `CayleyDickson<CayleyDickson<A, B>, CayleyDickson<C, D>>` represents a quaternion
public enum CayleyDickson<Re: Algebra, Im: Algebra>: Algebra {}

// MARK: - Integer Algebra conformances

extension Zero: Algebra {}
extension AddOne: Algebra {}
extension SubOne: Algebra {}
