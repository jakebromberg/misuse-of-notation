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

                typealias Convergent0 = GCFConvergent0<AddOne<Zero>>

                typealias ConvergentSumH1 = PlusSucc<PlusZero<AddOne<AddOne<Zero>>>>

                typealias ConvergentSumK1 = PlusZero<AddOne<AddOne<Zero>>>

                typealias Convergent1 = GCFConvergentStep<Convergent0, AddOne<Zero>.OneTimesProof.Distributed, AddOne<Zero>.OneTimesProof, ConvergentSumH1, AddOne<Zero>.OneTimesProof.Distributed, Zero.OneTimesProof, ConvergentSumK1>

                typealias MatrixPower0 = Matrix2<AddOne<Zero>, AddOne<Zero>, AddOne<Zero>, Zero>

                typealias MatrixSumAC1 = PlusSucc<PlusZero<AddOne<AddOne<Zero>>>>

                typealias MatrixSumBD1 = PlusZero<AddOne<AddOne<Zero>>>

                typealias MatrixPower1 = Sqrt2MatStep<MatrixPower0, AddOne<Zero>.OneTimesProof.Distributed, MatrixSumAC1, AddOne<Zero>.OneTimesProof.Distributed, MatrixSumBD1>

                func sqrt2CorrespondenceCheck() {
                    assertEqual(MatrixPower0.A.self, Convergent0.P.self)
                    assertEqual(MatrixPower0.B.self, Convergent0.Q.self)
                    assertEqual(MatrixPower1.A.self, Convergent1.P.self)
                    assertEqual(MatrixPower1.B.self, Convergent1.Q.self)
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
