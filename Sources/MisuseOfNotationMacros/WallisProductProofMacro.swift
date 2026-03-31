import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// `@WallisProductProof(depth: n)` -- generates the Wallis product proof to depth n.
///
/// The Wallis product for pi/2:
///   pi/2 = prod_{k=1}^{inf} (2k)^2 / ((2k-1)(2k+1))
///
/// At compile time, the macro computes:
///   1. Unreduced partial products W_0 = 1/1, W_1 = 4/3, W_2 = 64/45, ...
///   2. Two-step product decomposition: prev_p * 2k then result * 2k (numerator),
///      prev_q * (2k-1) then result * (2k+1) (denominator)
///   3. All NaturalProduct witnesses via ProductChainGenerator
///   4. WallisStep chain linking each step to the previous
///   5. Factor correspondence: for each k, (2k-1)(2k+1) + 1 = (2k)^2
///      witnessed by a PlusSucc<PlusZero<...>> chain
///
/// The type checker independently verifies every witness chain.
public struct WallisProductProofMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let argument = arguments.first?.expression,
              let literal = argument.as(IntegerLiteralExprSyntax.self),
              let depth = Int(literal.literal.text),
              depth >= 1 else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.wallisProductRequiresPositiveInteger)
            ])
        }

        // --- Compute unreduced Wallis partial products ---
        // W_0 = 1/1
        // W_k = W_{k-1} * (2k)^2 / ((2k-1)(2k+1))
        var WP = [1]  // numerators
        var WQ = [1]  // denominators

        for k in 1...depth {
            let twoK = 2 * k
            let numFactor = twoK * twoK          // (2k)^2
            let denFactor = (twoK - 1) * (twoK + 1)  // (2k-1)(2k+1)
            WP.append(WP[k - 1] * numFactor)
            WQ.append(WQ[k - 1] * denFactor)
        }

        // --- Collect needed product chains ---
        // Two-step decomposition: for each k,
        //   Numerator:   prev_p * 2k, then (prev_p * 2k) * 2k
        //   Denominator: prev_q * (2k-1), then (prev_q * (2k-1)) * (2k+1)
        var gen = ProductChainGenerator()

        for k in 1...depth {
            let twoK = 2 * k
            let twoKm1 = twoK - 1
            let twoKp1 = twoK + 1

            let prevP = WP[k - 1]
            let prevQ = WQ[k - 1]
            let midP = prevP * twoK     // prev_p * 2k
            let midQ = prevQ * twoKm1   // prev_q * (2k-1)

            gen.need(factor: prevP, multiplier: twoK)     // prev_p * 2k
            gen.need(factor: midP, multiplier: twoK)      // (prev_p * 2k) * 2k
            gen.need(factor: prevQ, multiplier: twoKm1)   // prev_q * (2k-1)
            gen.need(factor: midQ, multiplier: twoKp1)    // (prev_q * (2k-1)) * (2k+1)
        }

        // --- Generate product chains ---
        var decls: [DeclSyntax] = gen.declarations()

        // --- Generate Wallis step chain ---
        let w0: DeclSyntax = "typealias Wallis0 = WallisBase"
        decls.append(w0)

        for k in 1...depth {
            let twoK = 2 * k
            let twoKm1 = twoK - 1
            let twoKp1 = twoK + 1

            let prevP = WP[k - 1]
            let prevQ = WQ[k - 1]
            let midP = prevP * twoK
            let midQ = prevQ * twoKm1

            let pTimesTwoK = ProductChainGenerator.name(factor: prevP, multiplier: twoK)
            let midPTimesTwoK = ProductChainGenerator.name(factor: midP, multiplier: twoK)
            let qTimesTwoKm1 = ProductChainGenerator.name(factor: prevQ, multiplier: twoKm1)
            let midQTimesTwoKp1 = ProductChainGenerator.name(factor: midQ, multiplier: twoKp1)

            let wDecl: DeclSyntax = "typealias Wallis\(raw: String(k)) = WallisStep<Wallis\(raw: String(k - 1)), \(raw: pTimesTwoK), \(raw: midPTimesTwoK), \(raw: qTimesTwoKm1), \(raw: midQTimesTwoKp1)>"
            decls.append(wDecl)
        }

        // --- Generate factor correspondence ---
        // For each k: (2k-1)(2k+1) + 1 = (2k)^2
        // Witnessed by PlusSucc<PlusZero<peano((2k-1)(2k+1))>>
        for k in 1...depth {
            let twoK = 2 * k
            let denFactor = (twoK - 1) * (twoK + 1)  // left
            let witness = plusSuccChain(left: denFactor, right: 1)
            let fcDecl: DeclSyntax = "typealias WallisFactor\(raw: String(k)) = \(raw: witness)"
            decls.append(fcDecl)
        }

        // --- Generate factor check function ---
        var body = ""
        for k in 1...depth {
            let twoK = 2 * k
            let numFactor = twoK * twoK
            let peano = peanoTypeName(for: numFactor)
            body += "    assertEqual(WallisFactor\(k).Total.self, \(peano).self)\n"
        }
        let checkDecl: DeclSyntax = """
        func wallisFactorCheck() {
        \(raw: body)}
        """
        decls.append(checkDecl)

        return decls
    }
}
