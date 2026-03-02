import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Generates a PlusSucc^right(PlusZero<peano(left)>) witness chain as a string.
///
/// The resulting NaturalSum witness proves left + right = left + right,
/// with Left = peano(left), Right = peano(right), Total = peano(left + right).
func plusSuccChain(left: Int, right: Int) -> String {
    var result = "PlusZero<\(peanoTypeName(for: left))>"
    for _ in 0..<right {
        result = "PlusSucc<\(result)>"
    }
    return result
}

/// `#fibonacciProof(upTo: n)` -- generates FibonacciStep witness chains proving
/// the Fibonacci recurrence F(i-1) + F(i) = F(i+1) for i = 1 through n.
///
/// The macro computes Fibonacci numbers as regular integers at compile time,
/// then emits PlusSucc/PlusZero witness chains that the type checker verifies
/// independently. If the macro emits a wrong witness, compilation fails.
///
/// Expansion of `#fibonacciProof(upTo: 3)`:
/// ```swift
/// typealias FibonacciWitness1 = PlusSucc<PlusZero<Zero>>
/// typealias Fibonacci1 = FibonacciStep<Fibonacci0, FibonacciWitness1>
/// typealias FibonacciWitness2 = PlusSucc<PlusZero<AddOne<Zero>>>
/// typealias Fibonacci2 = FibonacciStep<Fibonacci1, FibonacciWitness2>
/// typealias FibonacciWitness3 = PlusSucc<PlusSucc<PlusZero<AddOne<Zero>>>>
/// typealias Fibonacci3 = FibonacciStep<Fibonacci2, FibonacciWitness3>
/// ```
public struct FibonacciProofMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let argument = arguments.first?.expression,
              let literal = argument.as(IntegerLiteralExprSyntax.self),
              let n = Int(literal.literal.text),
              n >= 1 else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.fibonacciProofRequiresPositiveInteger)
            ])
        }

        // Compute Fibonacci numbers: fibs[i] = F(i)
        var fibs = [0, 1]
        for i in 2...(n + 1) {
            fibs.append(fibs[i - 1] + fibs[i - 2])
        }

        var decls: [DeclSyntax] = []

        for i in 1...n {
            let left = fibs[i - 1]  // F(i-1) = Left operand of the sum witness
            let right = fibs[i]     // F(i) = number of PlusSucc wrappers

            // Build witness: PlusSucc^F(i)(PlusZero<peano(F(i-1))>)
            // This proves F(i-1) + F(i) = F(i+1)
            let witness = plusSuccChain(left: left, right: right)

            let prevName = i == 1 ? "Fibonacci0" : "Fibonacci\(i - 1)"

            let wDecl: DeclSyntax = "typealias FibonacciWitness\(raw: String(i)) = \(raw: witness)"
            let sDecl: DeclSyntax = "typealias Fibonacci\(raw: String(i)) = FibonacciStep<\(raw: prevName), FibonacciWitness\(raw: String(i))>"

            decls.append(wDecl)
            decls.append(sDecl)
        }

        return decls
    }
}
