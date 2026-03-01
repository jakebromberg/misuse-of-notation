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

                typealias _FibW1 = PlusSucc<PlusZero<Zero>>

                typealias _Fib1 = FibStep<Fib0, _FibW1>

                typealias _FibW2 = PlusSucc<PlusZero<AddOne<Zero>>>

                typealias _Fib2 = FibStep<_Fib1, _FibW2>

                typealias _FibW3 = PlusSucc<PlusSucc<PlusZero<AddOne<Zero>>>>

                typealias _Fib3 = FibStep<_Fib2, _FibW3>

                typealias _CF0 = GCFConv0<AddOne<Zero>>

                typealias _CFS_H1 = PlusSucc<PlusZero<AddOne<Zero>>>

                typealias _CFS_K1 = PlusZero<AddOne<Zero>>

                typealias _CF1 = GCFConvStep<_CF0, AddOne<Zero>.OneTimesProof, AddOne<Zero>.OneTimesProof, _CFS_H1, AddOne<Zero>.OneTimesProof, Zero.OneTimesProof, _CFS_K1>

                func _goldenRatioCorrespondenceCheck() {
                    assertEqual(_CF0.P.self, _Fib2.Current.self)
                    assertEqual(_CF0.Q.self, _Fib1.Current.self)
                    assertEqual(_CF1.P.self, _Fib3.Current.self)
                    assertEqual(_CF1.Q.self, _Fib2.Current.self)
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
