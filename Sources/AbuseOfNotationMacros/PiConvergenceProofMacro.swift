import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// `#piConvergenceProof(depth: n)` -- generates the complete Brouncker-Leibniz
/// correspondence proof to depth n.
///
/// At compile time, the macro computes:
///   1. CF convergents h_i/k_i for Brouncker's continued fraction for 4/pi
///   2. Leibniz partial sums S_i for the series pi/4 = 1 - 1/3 + 1/5 - ...
///   3. All NaturalProduct and NaturalSum witnesses needed
///   4. Type equality assertions proving h_i = S_{i+1}'s denominator
///      and k_i = S_{i+1}'s numerator
///
/// The type checker then independently verifies every witness chain. If any
/// arithmetic is wrong, compilation fails. The macro is the proof SEARCH;
/// the type checker is the proof VERIFIER.
public struct PiConvergenceProofMacro: MemberMacro {
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
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.piConvergenceRequiresPositiveInteger)
            ])
        }

        // --- Compute CF convergents h_i/k_i ---
        // H[0] = h_{-1} = 1, H[1] = h_0 = 1, H[i+1] = h_i
        // K[0] = k_{-1} = 0, K[1] = k_0 = 1, K[i+1] = k_i
        var H = [1, 1]  // H[0] = h_{-1}, H[1] = h_0
        var K = [0, 1]  // K[0] = k_{-1}, K[1] = k_0

        for i in 1...depth {
            let a = (2 * i - 1) * (2 * i - 1)  // a_i = (2i-1)^2
            let b = 2
            H.append(b * H[i] + a * H[i - 1])  // h_i = b*h_{i-1} + a_i*h_{i-2}
            K.append(b * K[i] + a * K[i - 1])  // k_i = b*k_{i-1} + a_i*k_{i-2}
        }

        // --- Compute Leibniz partial sums S_k = LP[k-1] / LQ[k-1] ---
        // S_1 = 1/1, then alternate subtract/add: S_2 = 1-1/3, S_3 = 2/3+1/5, ...
        var LP = [1]  // LP[0] = numerator of S_1
        var LQ = [1]  // LQ[0] = denominator of S_1

        for k in 2...(depth + 1) {
            let d = 2 * k - 1  // odd denominator: 3, 5, 7, 9, ...
            let p = LP[k - 2]
            let q = LQ[k - 2]
            let pd = p * d
            let qd = q * d

            if k % 2 == 0 {
                // Subtraction: S_k = (p*d - q) / (q*d)
                LP.append(pd - q)
            } else {
                // Addition: S_k = (p*d + q) / (q*d)
                LP.append(pd + q)
            }
            LQ.append(qd)
        }

        // --- Collect needed product chains ---
        var gen = ProductChainGenerator()

        // CF products: for each depth i, need b*h_{i-1}, a_i*h_{i-2}, b*k_{i-1}, a_i*k_{i-2}
        for i in 1...depth {
            let a = (2 * i - 1) * (2 * i - 1)
            gen.need(factor: 2, multiplier: H[i])       // b * h_{i-1}
            gen.need(factor: 2, multiplier: K[i])       // b * k_{i-1}
            gen.need(factor: a, multiplier: H[i - 1])   // a_i * h_{i-2}
            if K[i - 1] > 0 {
                gen.need(factor: a, multiplier: K[i - 1])  // a_i * k_{i-2} (skip when k_{-1} = 0)
            }
        }

        // Leibniz products: for each step k, need p*d and q*d
        for k in 2...(depth + 1) {
            let d = 2 * k - 1
            gen.need(factor: LP[k - 2], multiplier: d)   // p * d
            gen.need(factor: LQ[k - 2], multiplier: d)   // q * d
        }

        // --- Generate product chains ---
        var decls: [DeclSyntax] = gen.declarations()

        // --- Generate CF convergent chain ---
        let cf0: DeclSyntax = "typealias _CF0 = GCFConv0<\(raw: peanoTypeName(for: 1))>"
        decls.append(cf0)

        for i in 1...depth {
            let a = (2 * i - 1) * (2 * i - 1)
            let b = 2

            // Product witness references
            let bhp = ProductChainGenerator.name(factor: b, multiplier: H[i])
            let ahpp = ProductChainGenerator.name(factor: a, multiplier: H[i - 1])
            let bkp = ProductChainGenerator.name(factor: b, multiplier: K[i])
            let akpp: String
            if K[i - 1] == 0 {
                akpp = ProductChainGenerator.name(factor: a, multiplier: 0)
            } else {
                akpp = ProductChainGenerator.name(factor: a, multiplier: K[i - 1])
            }

            // Sum witnesses for h_i and k_i
            let bh = b * H[i]
            let ah = a * H[i - 1]
            let sumH = plusSuccChain(left: bh, right: ah)

            let bk = b * K[i]
            let ak = a * K[i - 1]
            let sumK = plusSuccChain(left: bk, right: ak)

            let hsDecl: DeclSyntax = "typealias _CFS_H\(raw: String(i)) = \(raw: sumH)"
            let ksDecl: DeclSyntax = "typealias _CFS_K\(raw: String(i)) = \(raw: sumK)"
            decls.append(hsDecl)
            decls.append(ksDecl)

            let cfDecl: DeclSyntax = "typealias _CF\(raw: String(i)) = GCFConvStep<_CF\(raw: String(i - 1)), \(raw: bhp), \(raw: ahpp), _CFS_H\(raw: String(i)), \(raw: bkp), \(raw: akpp), _CFS_K\(raw: String(i))>"
            decls.append(cfDecl)
        }

        // --- Generate Leibniz partial sum chain ---
        let ls1: DeclSyntax = "typealias _LS1 = LeibnizBase"
        decls.append(ls1)

        for k in 2...(depth + 1) {
            let d = 2 * k - 1
            let p = LP[k - 2]
            let q = LQ[k - 2]

            let pxd = ProductChainGenerator.name(factor: p, multiplier: d)
            let qxd = ProductChainGenerator.name(factor: q, multiplier: d)

            if k % 2 == 0 {
                // Subtraction: new_p = p*d - q, witnessed by new_p + q = p*d
                let newP = p * d - q
                let subWitness = plusSuccChain(left: newP, right: q)
                let wDecl: DeclSyntax = "typealias _LSW\(raw: String(k)) = \(raw: subWitness)"
                let sDecl: DeclSyntax = "typealias _LS\(raw: String(k)) = LeibnizSub<_LS\(raw: String(k - 1)), \(raw: pxd), \(raw: qxd), _LSW\(raw: String(k))>"
                decls.append(wDecl)
                decls.append(sDecl)
            } else {
                // Addition: new_p = p*d + q, witnessed by p*d + q = new_p
                let addWitness = plusSuccChain(left: p * d, right: q)
                let wDecl: DeclSyntax = "typealias _LSW\(raw: String(k)) = \(raw: addWitness)"
                let sDecl: DeclSyntax = "typealias _LS\(raw: String(k)) = LeibnizAdd<_LS\(raw: String(k - 1)), \(raw: pxd), \(raw: qxd), _LSW\(raw: String(k))>"
                decls.append(wDecl)
                decls.append(sDecl)
            }
        }

        // --- Generate correspondence check ---
        // A function whose body contains assertEqual calls. The function is never
        // called -- its compilation verifies all type equalities.
        var body = ""
        for i in 1...depth {
            let leibIdx = i + 1
            body += "    assertEqual(_CF\(i).P.self, _LS\(leibIdx).Q.self)\n"
            body += "    assertEqual(_CF\(i).Q.self, _LS\(leibIdx).P.self)\n"
        }
        let checkDecl: DeclSyntax = """
        func _piCorrespondenceCheck() {
        \(raw: body)}
        """
        decls.append(checkDecl)

        return decls
    }
}
