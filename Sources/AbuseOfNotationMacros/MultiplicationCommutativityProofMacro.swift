import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// `@MulCommProof(leftOperand: A, depth: D)` -- generates paired forward/reverse
/// multiplication proof chains showing `A * b = b * A` for `b = 0` through `D`.
///
/// Attach to a namespace enum:
/// ```swift
/// @MulCommProof(leftOperand: 4, depth: 5)
/// enum MulComm4 {}
/// ```
///
/// Each expansion generates `D+1` paired typealiases:
/// ```swift
/// enum MulComm4 {
///     typealias Forward0 = TimesZero<N4>
///     typealias Reverse0 = N4.ZeroTimesProof
///     typealias Forward1 = TimesGroup<TimesTick<TimesTick<TimesTick<TimesTick<Forward0>>>>>
///     typealias Reverse1 = Reverse0.Distributed
///     // ...
/// }
/// ```
///
/// The forward proof (`ForwardK`) witnesses `A * K` using the flat encoding:
/// each step wraps in A `TimesTick`s plus one `TimesGroup`.
/// The reverse proof (`ReverseK`) witnesses `K * A` via `SuccessorLeftMultiplication.Distributed`.
/// The type checker verifies that `ForwardK.Total == ReverseK.Total` when asserted.
public struct MultiplicationCommutativityProofMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.mulCommProofRequiresMultiplier)
            ])
        }

        // Parse labeled arguments: leftOperand and depth
        var leftOperand: Int?
        var depth: Int?

        for arg in arguments {
            let label = arg.label?.text
            guard let literal = arg.expression.as(IntegerLiteralExprSyntax.self),
                  let value = Int(literal.literal.text) else {
                continue
            }
            switch label {
            case "leftOperand":
                leftOperand = value
            case "depth":
                depth = value
            default:
                break
            }
        }

        guard let a = leftOperand, a >= 2, let d = depth, d >= 1 else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.mulCommProofRequiresMultiplier)
            ])
        }

        let peano = peanoTypeName(for: a)
        var decls: [DeclSyntax] = []

        // Base case (b = 0): A * 0 = 0 and 0 * A = 0
        decls.append("typealias Forward0 = TimesZero<\(raw: peano)>")
        decls.append("typealias Reverse0 = \(raw: peano).ZeroTimesProof")

        // Inductive steps (b = 1 through d)
        for b in 1...d {
            let prev = "Forward\(b - 1)"

            // Forward: TimesGroup<TimesTick^A<prev>>
            let fwd = "TimesGroup<"
                + String(repeating: "TimesTick<", count: a)
                + prev
                + String(repeating: ">", count: a + 1)

            // Reverse: prev.Distributed
            let rev = "Reverse\(b - 1).Distributed"

            decls.append("typealias Forward\(raw: String(b)) = \(raw: fwd)")
            decls.append("typealias Reverse\(raw: String(b)) = \(raw: rev)")
        }

        return decls
    }
}
