import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AbuseOfNotationMacros)
import AbuseOfNotationMacros

nonisolated(unsafe) let goldenRatioProofMacros: [String: Macro.Type] = [
    "GoldenRatioProof": GoldenRatioProofMacro.self,
]
#endif

final class GoldenRatioProofMacroTests: XCTestCase {
    #if canImport(AbuseOfNotationMacros)

    func testDepthOne() throws {
        // Depth 1: CF [1;1,...] convergents h_0=1, h_1=2, k_0=1, k_1=1
        // Fibonacci: F(1)=1, F(2)=1, F(3)=2
        // Proves h_i = F(i+2) and k_i = F(i+1)
        assertMacroExpansion(
            """
            @GoldenRatioProof(depth: 1)
            enum GoldenRatioProof {}
            """,
            expandedSource: """
            enum GoldenRatioProof {

                typealias FibonacciWitness1 = PlusSucc<PlusZero<Zero>>

                typealias Fibonacci1 = FibonacciStep<Fibonacci0, FibonacciWitness1>

                typealias FibonacciWitness2 = PlusSucc<PlusZero<AddOne<Zero>>>

                typealias Fibonacci2 = FibonacciStep<Fibonacci1, FibonacciWitness2>

                typealias FibonacciWitness3 = PlusSucc<PlusSucc<PlusZero<AddOne<Zero>>>>

                typealias Fibonacci3 = FibonacciStep<Fibonacci2, FibonacciWitness3>

                typealias Convergent0 = GCFConvergent0<AddOne<Zero>>

                typealias ConvergentSumH1 = PlusSucc<PlusZero<AddOne<Zero>>>

                typealias ConvergentSumK1 = PlusZero<AddOne<Zero>>

                typealias Convergent1 = GCFConvergentStep<Convergent0, AddOne<Zero>.OneTimesProof, AddOne<Zero>.OneTimesProof, ConvergentSumH1, AddOne<Zero>.OneTimesProof, Zero.OneTimesProof, ConvergentSumK1>

                func goldenRatioCorrespondenceCheck() {
                    assertEqual(Convergent0.P.self, Fibonacci2.Current.self)
                    assertEqual(Convergent0.Q.self, Fibonacci1.Current.self)
                    assertEqual(Convergent1.P.self, Fibonacci3.Current.self)
                    assertEqual(Convergent1.Q.self, Fibonacci2.Current.self)
                }
            }
            """,
            macros: goldenRatioProofMacros
        )
    }

    func testZeroProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @GoldenRatioProof(depth: 0)
            enum GoldenRatioProof {}
            """,
            expandedSource: """
            enum GoldenRatioProof {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#goldenRatioProof requires an integer literal >= 1", line: 1, column: 1)
            ],
            macros: goldenRatioProofMacros
        )
    }

    #endif
}
