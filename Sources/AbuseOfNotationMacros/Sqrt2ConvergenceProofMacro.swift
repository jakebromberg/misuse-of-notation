import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// `@Sqrt2ConvergenceProof(depth: n)` -- generates the proof that the sqrt(2)
/// continued fraction [1; 2, 2, 2, ...] convergents match left-multiplication
/// by the matrix [[2,1],[1,0]].
///
/// At compile time, the macro computes:
///   1. Product witness chains for factors 1 and 2
///   2. CF convergent chain Convergent0...Convergent{n} for [1; 2, 2, ...]
///   3. Matrix power chain Matrix0...Matrix{n} via Sqrt2MatStep
///   4. Correspondence check: MAT_i entries match CF_i convergents
///
/// The type checker independently verifies every witness chain.
public struct Sqrt2ConvergenceProofMacro: MemberMacro {
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
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.sqrt2ConvergenceRequiresPositiveInteger)
            ])
        }

        // --- Compute CF convergents for [1; 2, 2, 2, ...] ---
        // h_{-1}=1, h_0=b_0=1, h_i = 2*h_{i-1} + 1*h_{i-2}
        // k_{-1}=0, k_0=1,     k_i = 2*k_{i-1} + 1*k_{i-2}
        var H = [1, 1]  // H[0]=h_{-1}, H[1]=h_0
        var K = [0, 1]  // K[0]=k_{-1}, K[1]=k_0
        for i in 1...depth {
            H.append(2 * H[i] + 1 * H[i - 1])
            K.append(2 * K[i] + 1 * K[i - 1])
        }

        // --- Compute matrix chain [[2,1],[1,0]]^n applied to [[1,1],[1,0]] ---
        // mat[i] = (a, b, c, d) where a=h_i, b=k_i, c=h_{i-1}, d=k_{i-1}
        var matA = [1], matB = [1], matC = [1], matD = [0]  // MAT0
        for i in 1...depth {
            let prevA = matA[i - 1], prevB = matB[i - 1]
            let prevC = matC[i - 1], prevD = matD[i - 1]
            matA.append(2 * prevA + prevC)
            matB.append(2 * prevB + prevD)
            matC.append(prevA)
            matD.append(prevB)
        }

        // --- Generate CF convergent chain ---
        // All products use factors 1 and 2, handled by universal theorems
        // (MultiplicationLeftOne and SuccessorLeftMultiplication.Distributed).
        var decls: [DeclSyntax] = []
        decls.append("typealias Convergent0 = GCFConvergent0<\(raw: peanoTypeName(for: 1))>")

        for i in 1...depth {
            let b = 2
            let bhp = ProductChainGenerator.name(factor: b, multiplier: H[i])
            let ahpp = ProductChainGenerator.name(factor: 1, multiplier: H[i - 1])
            let bkp = ProductChainGenerator.name(factor: b, multiplier: K[i])
            let akpp = ProductChainGenerator.name(factor: 1, multiplier: K[i - 1])

            let bh = b * H[i]
            let ah = 1 * H[i - 1]
            let sumH = plusSuccChain(left: bh, right: ah)

            let bk = b * K[i]
            let ak = 1 * K[i - 1]
            let sumK = plusSuccChain(left: bk, right: ak)

            decls.append("typealias ConvergentSumH\(raw: String(i)) = \(raw: sumH)")
            decls.append("typealias ConvergentSumK\(raw: String(i)) = \(raw: sumK)")
            decls.append("typealias Convergent\(raw: String(i)) = GCFConvergentStep<Convergent\(raw: String(i - 1)), \(raw: bhp), \(raw: ahpp), ConvergentSumH\(raw: String(i)), \(raw: bkp), \(raw: akpp), ConvergentSumK\(raw: String(i))>")
        }

        // --- Generate matrix power chain ---
        decls.append("typealias MatrixPower0 = Matrix2<\(raw: peanoTypeName(for: matA[0])), \(raw: peanoTypeName(for: matB[0])), \(raw: peanoTypeName(for: matC[0])), \(raw: peanoTypeName(for: matD[0]))>")

        for i in 1...depth {
            let prevA = matA[i - 1], prevB = matB[i - 1]
            let prevC = matC[i - 1], prevD = matD[i - 1]
            // TwoA witness: 2 * prevA
            let twoAName = ProductChainGenerator.name(factor: 2, multiplier: prevA)
            // TwoB witness: 2 * prevB
            let twoBName = ProductChainGenerator.name(factor: 2, multiplier: prevB)

            // Sum witness: 2*prevA + prevC
            let sumAC = plusSuccChain(left: 2 * prevA, right: prevC)
            // Sum witness: 2*prevB + prevD
            let sumBD = plusSuccChain(left: 2 * prevB, right: prevD)

            decls.append("typealias MatrixSumAC\(raw: String(i)) = \(raw: sumAC)")
            decls.append("typealias MatrixSumBD\(raw: String(i)) = \(raw: sumBD)")
            decls.append("typealias MatrixPower\(raw: String(i)) = Sqrt2MatStep<MatrixPower\(raw: String(i - 1)), \(raw: twoAName), MatrixSumAC\(raw: String(i)), \(raw: twoBName), MatrixSumBD\(raw: String(i))>")
        }

        // --- Generate correspondence check ---
        var body = ""
        for i in 0...depth {
            body += "    assertEqual(MatrixPower\(i).A.self, Convergent\(i).P.self)\n"
            body += "    assertEqual(MatrixPower\(i).B.self, Convergent\(i).Q.self)\n"
        }
        let checkDecl: DeclSyntax = """
        func sqrt2CorrespondenceCheck() {
        \(raw: body)}
        """
        decls.append(checkDecl)

        return decls
    }
}
