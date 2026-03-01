import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AbuseOfNotationMacros)
import AbuseOfNotationMacros

nonisolated(unsafe) let piConvergenceProofMacros: [String: Macro.Type] = [
    "PiConvergenceProof": PiConvergenceProofMacro.self,
]
#endif

final class PiConvergenceProofMacroTests: XCTestCase {
    #if canImport(AbuseOfNotationMacros)

    func testDepthOne() throws {
        // Depth 1: CF convergent h_1/k_1 = 3/2, Leibniz S_2 = 2/3
        // Proves h_1 = S_2.Q (3=3) and k_1 = S_2.P (2=2)
        assertMacroExpansion(
            """
            @PiConvergenceProof(depth: 1)
            enum PiProof {}
            """,
            expandedSource: """
            enum PiProof {

                typealias _CF0 = GCFConv0<AddOne<Zero>>

                typealias _CFS_H1 = PlusSucc<PlusZero<AddOne<AddOne<Zero>>>>

                typealias _CFS_K1 = PlusZero<AddOne<AddOne<Zero>>>

                typealias _CF1 = GCFConvStep<_CF0, AddOne<Zero>.OneTimesProof.Distributed, AddOne<Zero>.OneTimesProof, _CFS_H1, AddOne<Zero>.OneTimesProof.Distributed, Zero.OneTimesProof, _CFS_K1>

                typealias _LS1 = LeibnizBase

                typealias _LSW2 = PlusSucc<PlusZero<AddOne<AddOne<Zero>>>>

                typealias _LS2 = LeibnizSub<_LS1, AddOne<AddOne<AddOne<Zero>>>.OneTimesProof, AddOne<AddOne<AddOne<Zero>>>.OneTimesProof, _LSW2>

                func _piCorrespondenceCheck() {
                    assertEqual(_CF1.P.self, _LS2.Q.self)
                    assertEqual(_CF1.Q.self, _LS2.P.self)
                }
            }
            """,
            macros: piConvergenceProofMacros
        )
    }

    func testZeroProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @PiConvergenceProof(depth: 0)
            enum PiProof {}
            """,
            expandedSource: """
            enum PiProof {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#piConvergenceProof requires an integer literal >= 1", line: 1, column: 1)
            ],
            macros: piConvergenceProofMacros
        )
    }

    #endif
}
