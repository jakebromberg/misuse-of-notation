import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// `@CFDeterminantProof(coefficients: [b_0, b_1, ..., b_d])` -- generates the CF convergent
/// determinant identity proof for any simple continued fraction with the given partial quotients.
///
/// The CF convergent determinant identity states:
///   h_n * k_{n-1} - h_{n-1} * k_n = (-1)^{n+1}
///
/// For the golden ratio CF [1;1,1,...], this yields the Cassini identity.
/// For the sqrt(2) CF [1;2,2,...], it yields the Pell equation determinant.
/// The same macro proves both -- making explicit that they are instances of one structure.
///
/// The macro computes convergents internally, generates shared SuccessorLeftMultiplication
/// chains grouped by Right value, and emits determinant sum witnesses at each step.
///
/// For a product `a * b`:
/// - If b == 0: `TimesZero<peano(a)>`
/// - If b >= 1: base is `peano(b).OneTimesProof` (1*b=b), then chain (a-1) `.Distributed` steps.
/// Chains are grouped by Right value (b) to share prefixes.
///
/// At step n:
/// - Even n (det = -1): `h_{n-1}*k_n` is larger. Assert `smaller + 1 = PrevHTimesK.Total`
/// - Odd n  (det = +1): `h_n*k_{n-1}` is larger. Assert `smaller + 1 = HTimesPrevK.Total`
public struct CFDeterminantProofMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // --- Parse coefficients array ---
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let argument = arguments.first?.expression,
              let arrayExpr = argument.as(ArrayExprSyntax.self) else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.cfDeterminantRequiresCoefficients)
            ])
        }

        var coefficients: [Int] = []
        for element in arrayExpr.elements {
            guard let literal = element.expression.as(IntegerLiteralExprSyntax.self),
                  let value = Int(literal.literal.text),
                  value >= 1 else {
                throw DiagnosticsError(diagnostics: [
                    Diagnostic(node: Syntax(node), message: PeanoDiagnostic.cfDeterminantRequiresCoefficients)
                ])
            }
            coefficients.append(value)
        }

        guard coefficients.count >= 2 else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.cfDeterminantRequiresCoefficients)
            ])
        }

        let depth = coefficients.count - 1  // number of determinant steps

        // --- Compute CF convergents ---
        // H[0] = h_{-1} = 1, H[1] = h_0 = b_0
        // K[0] = k_{-1} = 0, K[1] = k_0 = 1
        // H[i+1] = b_i * H[i] + H[i-1], K[i+1] = b_i * K[i] + K[i-1]
        var H = [1, coefficients[0]]
        var K = [0, 1]
        for i in 1...depth {
            H.append(coefficients[i] * H[i] + H[i - 1])
            K.append(coefficients[i] * K[i] + K[i - 1])
        }

        // --- Collect needed products as (Left, Right) pairs ---
        // Products: h_n * k_{n-1} and h_{n-1} * k_n at each step n (0..depth)
        // Product a*b: Left=a, Right=b. Chain name: Chain{Right}x{Left}.
        // Group by Right to share chain prefixes.
        var maxLeftByRight: [Int: Int] = [:]  // right -> max left needed

        for n in 0...depth {
            let hN = H[n + 1]     // h_n
            let kPrevN = K[n]     // k_{n-1}
            let hPrevN = H[n]     // h_{n-1}
            let kN = K[n + 1]     // k_n

            // h_n * k_{n-1}: skip if k_{n-1} == 0
            if kPrevN > 0 {
                maxLeftByRight[kPrevN] = max(maxLeftByRight[kPrevN] ?? 0, hN)
            }
            // h_{n-1} * k_n: skip if k_n == 0 (never happens for n >= 0)
            if kN > 0 {
                maxLeftByRight[kN] = max(maxLeftByRight[kN] ?? 0, hPrevN)
            }
        }

        var decls: [DeclSyntax] = []

        // --- Generate chain typealiases grouped by Right value ---
        for right in maxLeftByRight.keys.sorted() {
            let maxLeft = maxLeftByRight[right]!
            // Base: Chain{right}x1 = peano(right).OneTimesProof (1 * right = right)
            decls.append("typealias Chain\(raw: String(right))x1 = \(raw: peanoTypeName(for: right)).OneTimesProof")
            // Each .Distributed increments Left by 1
            for left in 2...maxLeft {
                decls.append("typealias Chain\(raw: String(right))x\(raw: String(left)) = Chain\(raw: String(right))x\(raw: String(left - 1)).Distributed")
            }
        }

        // --- Generate step products and determinant witnesses ---
        for n in 0...depth {
            let hN = H[n + 1]     // h_n
            let kPrevN = K[n]     // k_{n-1}
            let hPrevN = H[n]     // h_{n-1}
            let kN = K[n + 1]     // k_n

            // HTimesPrevK{n} = h_n * k_{n-1}
            let hTimesPrevKName: String
            if kPrevN == 0 {
                hTimesPrevKName = "TimesZero<\(peanoTypeName(for: hN))>"
            } else {
                hTimesPrevKName = "Chain\(kPrevN)x\(hN)"
            }
            decls.append("typealias HTimesPrevK\(raw: String(n)) = \(raw: hTimesPrevKName)")

            // PrevHTimesK{n} = h_{n-1} * k_n
            let prevHTimesKName: String
            if kN == 0 {
                prevHTimesKName = "TimesZero<\(peanoTypeName(for: hPrevN))>"
            } else {
                prevHTimesKName = "Chain\(kN)x\(hPrevN)"
            }
            decls.append("typealias PrevHTimesK\(raw: String(n)) = \(raw: prevHTimesKName)")

            // Determinant sum witness: smaller + 1 = larger
            let hTimesKPrev = hN * kPrevN
            let hPrevTimesK = hPrevN * kN
            let smaller = min(hTimesKPrev, hPrevTimesK)
            let detWitness = "PlusSucc<PlusZero<\(peanoTypeName(for: smaller))>>"
            decls.append("typealias Determinant\(raw: String(n)) = \(raw: detWitness)")
        }

        // --- Generate check function ---
        var body = ""
        for n in 0...depth {
            if n % 2 == 0 {
                // Even: PrevHTimesK is larger
                body += "    assertEqual(Determinant\(n).Total.self, PrevHTimesK\(n).Total.self)\n"
            } else {
                // Odd: HTimesPrevK is larger
                body += "    assertEqual(Determinant\(n).Total.self, HTimesPrevK\(n).Total.self)\n"
            }
        }
        let checkDecl: DeclSyntax = """
        func determinantCheck() {
        \(raw: body)}
        """
        decls.append(checkDecl)

        return decls
    }
}
