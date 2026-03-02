import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AbuseOfNotationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProductConformanceMacro.self,
        FibonacciProofMacro.self,
        PiConvergenceProofMacro.self,
        GoldenRatioProofMacro.self,
        Sqrt2ConvergenceProofMacro.self,
        MultiplicationCommutativityProofMacro.self,
        WallisProductProofMacro.self,
    ]
}
