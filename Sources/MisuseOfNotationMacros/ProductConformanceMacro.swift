import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

func peanoTypeName(for n: Int) -> String {
    if n == 0 { return "Zero" }
    if n > 0 {
        return String(repeating: "AddOne<", count: n) + "Zero" + String(repeating: ">", count: n)
    }
    return String(repeating: "SubOne<", count: -n) + "Zero" + String(repeating: ">", count: -n)
}

/// `@ProductConformance(n)` -- generates an inductive protocol, conformances, and
/// a `Product` extension for type-level multiplication by `n`.
///
/// Attach to the `Product` enum declaration:
/// ```swift
/// @ProductConformance(2)
/// @ProductConformance(3)
/// enum Product<L: Natural, R: Natural> {}
/// ```
///
/// Each `@ProductConformance(2)` expands to peer declarations:
/// ```swift
/// protocol TimesN2: Natural {
///     associatedtype TimesN2Result: Natural
/// }
/// extension Zero: TimesN2 {
///     typealias TimesN2Result = Zero
/// }
/// extension AddOne: TimesN2 where Predecessor: TimesN2 {
///     typealias TimesN2Result = AddOne<AddOne<Predecessor.TimesN2Result>>
/// }
/// extension Product where L == AddOne<AddOne<Zero>>, R: TimesN2 {
///     typealias Result = R.TimesN2Result
/// }
/// ```
public struct ProductConformanceMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let argument = arguments.first?.expression,
              let literal = argument.as(IntegerLiteralExprSyntax.self),
              let n = Int(literal.literal.text),
              n >= 2 else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: Syntax(node), message: PeanoDiagnostic.productConformanceRequiresMultiplier)
            ])
        }

        let proto = "TimesN\(n)"
        let assoc = "TimesN\(n)Result"
        let addOneChain = String(repeating: "AddOne<", count: n) + "Predecessor.\(assoc)" + String(repeating: ">", count: n)
        let lType = peanoTypeName(for: n)

        return [
            """
            protocol \(raw: proto): Natural {
                associatedtype \(raw: assoc): Natural
            }
            """,
            """
            extension Zero: \(raw: proto) {
                typealias \(raw: assoc) = Zero
            }
            """,
            """
            extension AddOne: \(raw: proto) where Predecessor: \(raw: proto) {
                typealias \(raw: assoc) = \(raw: addOneChain)
            }
            """,
            """
            extension Product where L == \(raw: lType), R: \(raw: proto) {
                typealias Result = R.\(raw: assoc)
            }
            """,
        ]
    }
}
