import SwiftSyntax

/// Collects needed product witness chains and generates `TimesZero`/`TimesSucc`
/// typealias declarations.
///
/// Multiple proof macros need the same pattern: emit `Product{factor}x0 = TimesZero<peano(factor)>`
/// followed by `Product{factor}x{m} = TimesSucc<..., PlusSuccChain>` up to a maximum multiplier.
/// This struct deduplicates that logic.
///
/// Factors 1 and 2 are handled by universal theorems (`MultiplicationLeftOne` and
/// `SuccessorLeftMultiplication.Distributed`) and never generate chains. The `name()` method
/// routes these to `peano(multiplier).OneTimesProof[.Distributed]`.
///
/// Each macro expansion creates its own local instance. Since member macros emit
/// declarations inside a namespace enum, the `Product{f}x{n}` names are scoped per enum.
struct ProductChainGenerator {
    /// Factors handled by universal theorems instead of generated chains.
    static let universalFactors: Set<Int> = [1, 2]

    private var products: [Int: Int] = [:]  // products[factor] = max multiplier

    mutating func need(factor: Int, multiplier: Int) {
        guard !Self.universalFactors.contains(factor) else { return }
        products[factor] = max(products[factor] ?? 0, multiplier)
    }

    func declarations() -> [DeclSyntax] {
        var decls: [DeclSyntax] = []
        for factor in products.keys.sorted() {
            let maxMul = products[factor]!
            decls.append("typealias Product\(raw: String(factor))x0 = TimesZero<\(raw: peanoTypeName(for: factor))>")
            for m in 1...maxMul {
                let addWitness = plusSuccChain(left: factor * (m - 1), right: factor)
                decls.append("typealias Product\(raw: String(factor))x\(raw: String(m)) = TimesSucc<Product\(raw: String(factor))x\(raw: String(m - 1)), \(raw: addWitness)>")
            }
        }
        return decls
    }

    /// Returns the name of the product witness for `factor * multiplier`.
    ///
    /// For factors 1 and 2, returns references to universal theorems:
    /// - Factor 1: `peano(multiplier).OneTimesProof` (via `MultiplicationLeftOne`)
    /// - Factor 2: `peano(multiplier).OneTimesProof.Distributed` (via `SuccessorLeftMultiplication`)
    /// - Other factors: `Product{factor}x{multiplier}` (generated chain)
    static func name(factor: Int, multiplier: Int) -> String {
        switch factor {
        case 1:
            return "\(peanoTypeName(for: multiplier)).OneTimesProof"
        case 2:
            return "\(peanoTypeName(for: multiplier)).OneTimesProof.Distributed"
        default:
            return "Product\(factor)x\(multiplier)"
        }
    }
}
