import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AbuseOfNotationMacros)
import AbuseOfNotationMacros

nonisolated(unsafe) let sqrt2ConvergenceProofMacros: [String: Macro.Type] = [
    "Sqrt2ConvergenceProof": Sqrt2ConvergenceProofMacro.self,
]
#endif

final class Sqrt2ConvergenceProofMacroTests: XCTestCase {
    #if canImport(AbuseOfNotationMacros)

    func testDepthOne() throws {
        // Depth 1: CF [1;2,...] convergents h_0=1, h_1=3, k_0=1, k_1=2
        // Matrix: MAT0=[[1,1],[1,0]], MAT1=[[3,2],[1,1]]
        // Proves MAT_i entries match CF_i convergents
        assertMacroExpansion(
            """
            @Sqrt2ConvergenceProof(depth: 1)
            enum Sqrt2Proof {}
            """,
            expandedSource: """
            enum Sqrt2Proof {

                typealias _CF0 = GCFConv0<AddOne<Zero>>

                typealias _CFS_H1 = PlusSucc<PlusZero<AddOne<AddOne<Zero>>>>

                typealias _CFS_K1 = PlusZero<AddOne<AddOne<Zero>>>

                typealias _CF1 = GCFConvStep<_CF0, AddOne<Zero>.OneTimesProof.Distributed, AddOne<Zero>.OneTimesProof, _CFS_H1, AddOne<Zero>.OneTimesProof.Distributed, Zero.OneTimesProof, _CFS_K1>

                typealias _MAT0 = Mat2<AddOne<Zero>, AddOne<Zero>, AddOne<Zero>, Zero>

                typealias _MATS_AC1 = PlusSucc<PlusZero<AddOne<AddOne<Zero>>>>

                typealias _MATS_BD1 = PlusZero<AddOne<AddOne<Zero>>>

                typealias _MAT1 = Sqrt2MatStep<_MAT0, AddOne<Zero>.OneTimesProof.Distributed, _MATS_AC1, AddOne<Zero>.OneTimesProof.Distributed, _MATS_BD1>

                func _sqrt2CorrespondenceCheck() {
                    assertEqual(_MAT0.A.self, _CF0.P.self)
                    assertEqual(_MAT0.B.self, _CF0.Q.self)
                    assertEqual(_MAT1.A.self, _CF1.P.self)
                    assertEqual(_MAT1.B.self, _CF1.Q.self)
                }
            }
            """,
            macros: sqrt2ConvergenceProofMacros
        )
    }

    func testZeroProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @Sqrt2ConvergenceProof(depth: 0)
            enum Sqrt2Proof {}
            """,
            expandedSource: """
            enum Sqrt2Proof {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#sqrt2ConvergenceProof requires an integer literal >= 1", line: 1, column: 1)
            ],
            macros: sqrt2ConvergenceProofMacros
        )
    }

    #endif
}
