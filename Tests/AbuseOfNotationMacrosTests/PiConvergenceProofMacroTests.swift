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

                typealias Convergent0 = GCFConvergent0<AddOne<Zero>>

                typealias ConvergentSumH1 = PlusSucc<PlusZero<AddOne<AddOne<Zero>>>>

                typealias ConvergentSumK1 = PlusZero<AddOne<AddOne<Zero>>>

                typealias Convergent1 = GCFConvergentStep<Convergent0, AddOne<Zero>.OneTimesProof.Distributed, AddOne<Zero>.OneTimesProof, ConvergentSumH1, AddOne<Zero>.OneTimesProof.Distributed, Zero.OneTimesProof, ConvergentSumK1>

                typealias LeibnizSum1 = LeibnizBase

                typealias LeibnizWitness2 = PlusSucc<PlusZero<AddOne<AddOne<Zero>>>>

                typealias LeibnizSum2 = LeibnizSub<LeibnizSum1, AddOne<AddOne<AddOne<Zero>>>.OneTimesProof, AddOne<AddOne<AddOne<Zero>>>.OneTimesProof, LeibnizWitness2>

                func piCorrespondenceCheck() {
                    assertEqual(Convergent1.P.self, LeibnizSum2.Q.self)
                    assertEqual(Convergent1.Q.self, LeibnizSum2.P.self)
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
