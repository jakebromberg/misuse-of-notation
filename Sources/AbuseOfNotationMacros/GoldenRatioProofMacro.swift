import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// `@GoldenRatioProof(depth: n)` -- generates the proof that the golden ratio
/// continued fraction [1; 1, 1, 1, ...] produces Fibonacci numbers as its
/// convergents.
///
/// At compile time, the macro computes:
///   1. Fibonacci witness chain _Fib1..._Fib{n+2} (reusing library Fib0 as base)
///   2. Product witness chain for factor=1 (trivial: 1*k)
///   3. CF convergent chain _CF0..._CF{n} for the all-ones CF
///   4. Correspondence check: h_i = F(i+2), k_i = F(i+1)
///
/// The type checker independently verifies every witness chain. If any
/// arithmetic is wrong, compilation fails.
public struct GoldenRatioProofMacro: MemberMacro {
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
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.goldenRatioRequiresPositiveInteger)
            ])
        }

        // --- Compute Fibonacci numbers ---
        // fibs[i] = F(i), need up to F(depth+2) for h_n = F(n+2)
        var fibs = [0, 1]
        for i in 2...(depth + 2) {
            fibs.append(fibs[i - 1] + fibs[i - 2])
        }

        // --- Compute CF convergents for [1; 1, 1, 1, ...] ---
        // h_{-1}=1, h_0=1, h_i = 1*h_{i-1} + 1*h_{i-2} = h_{i-1} + h_{i-2}
        // k_{-1}=0, k_0=1, k_i = 1*k_{i-1} + 1*k_{i-2} = k_{i-1} + k_{i-2}
        var H = [1, 1]  // H[0]=h_{-1}, H[1]=h_0
        var K = [0, 1]  // K[0]=k_{-1}, K[1]=k_0
        for i in 1...depth {
            H.append(H[i] + H[i - 1])
            K.append(K[i] + K[i - 1])
        }

        var decls: [DeclSyntax] = []

        // --- Generate Fibonacci witness chain ---
        // _Fib1..._Fib{depth+2}, same logic as FibonacciProofMacro
        let maxFib = depth + 2
        for i in 1...maxFib {
            let left = fibs[i - 1]
            let right = fibs[i]
            let witness = plusSuccChain(left: left, right: right)
            let prevName = i == 1 ? "Fib0" : "_Fib\(i - 1)"

            decls.append("typealias _FibW\(raw: String(i)) = \(raw: witness)")
            decls.append("typealias _Fib\(raw: String(i)) = FibStep<\(raw: prevName), _FibW\(raw: String(i))>")
        }

        // --- Generate CF convergent chain ---
        // All products use factor=1, handled by MulLeftOne (universal theorem).
        decls.append("typealias _CF0 = GCFConv0<\(raw: peanoTypeName(for: 1))>")

        for i in 1...depth {
            // a=1, b=1 for the golden ratio CF
            let bhp = ProductChainGenerator.name(factor: 1, multiplier: H[i])
            let ahpp = ProductChainGenerator.name(factor: 1, multiplier: H[i - 1])
            let bkp = ProductChainGenerator.name(factor: 1, multiplier: K[i])
            let akpp = ProductChainGenerator.name(factor: 1, multiplier: K[i - 1])

            // Sum witnesses: h_i = b*h_{i-1} + a*h_{i-2} = H[i] + H[i-1]
            let sumH = plusSuccChain(left: 1 * H[i], right: 1 * H[i - 1])
            let sumK = plusSuccChain(left: 1 * K[i], right: 1 * K[i - 1])

            decls.append("typealias _CFS_H\(raw: String(i)) = \(raw: sumH)")
            decls.append("typealias _CFS_K\(raw: String(i)) = \(raw: sumK)")
            decls.append("typealias _CF\(raw: String(i)) = GCFConvStep<_CF\(raw: String(i - 1)), \(raw: bhp), \(raw: ahpp), _CFS_H\(raw: String(i)), \(raw: bkp), \(raw: akpp), _CFS_K\(raw: String(i))>")
        }

        // --- Generate correspondence check ---
        // h_i = F(i+2) and k_i = F(i+1)
        var body = ""
        for i in 0...depth {
            let fibH = i + 2  // h_i should equal F(i+2)
            let fibK = i + 1  // k_i should equal F(i+1)
            body += "    assertEqual(_CF\(i).P.self, _Fib\(fibH).Current.self)\n"
            body += "    assertEqual(_CF\(i).Q.self, _Fib\(fibK).Current.self)\n"
        }
        let checkDecl: DeclSyntax = """
        func _goldenRatioCorrespondenceCheck() {
        \(raw: body)}
        """
        decls.append(checkDecl)

        return decls
    }
}
