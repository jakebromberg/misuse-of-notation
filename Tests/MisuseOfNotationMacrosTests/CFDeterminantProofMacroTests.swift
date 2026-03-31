import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MisuseOfNotationMacros)
import MisuseOfNotationMacros

nonisolated(unsafe) let cfDeterminantProofMacros: [String: Macro.Type] = [
    "CFDeterminantProof": CFDeterminantProofMacro.self,
]
#endif

final class CFDeterminantProofMacroTests: XCTestCase {
    #if canImport(MisuseOfNotationMacros)

    func testDepthOneGoldenRatioCoefficients() throws {
        // [1, 1]: h=[-1:1, 0:1, 1:2], k=[-1:0, 0:1, 1:1]
        // Step 0 (even): h_0*k_{-1}=1*0, h_{-1}*k_0=1*1, det: 0+1=1
        // Step 1 (odd):  h_1*k_0=2*1,   h_0*k_1=1*1,   det: 1+1=2
        assertMacroExpansion(
            """
            @CFDeterminantProof(coefficients: [1, 1])
            enum PhiDet {}
            """,
            expandedSource: """
            enum PhiDet {

                typealias Chain1x1 = AddOne<Zero>.OneTimesProof

                typealias Chain1x2 = Chain1x1.Distributed

                typealias HTimesPrevK0 = TimesZero<AddOne<Zero>>

                typealias PrevHTimesK0 = Chain1x1

                typealias Determinant0 = PlusSucc<PlusZero<Zero>>

                typealias HTimesPrevK1 = Chain1x2

                typealias PrevHTimesK1 = Chain1x1

                typealias Determinant1 = PlusSucc<PlusZero<AddOne<Zero>>>

                func determinantCheck() {
                    assertEqual(Determinant0.Total.self, PrevHTimesK0.Total.self)
                    assertEqual(Determinant1.Total.self, HTimesPrevK1.Total.self)
                }
            }
            """,
            macros: cfDeterminantProofMacros
        )
    }

    func testDepthTwoSqrt2Coefficients() throws {
        // [1, 2, 2]: h=[-1:1, 0:1, 1:3, 2:7], k=[-1:0, 0:1, 1:2, 2:5]
        // Step 0 (even): h_0*k_{-1}=1*0, h_{-1}*k_0=1*1=1, det: 0+1=1
        // Step 1 (odd):  h_1*k_0=3*1=3,  h_0*k_1=1*1=1,    det: 1+1=2 (wait, 3-1=2? no)
        // Actually: h_1*k_0=3*1=3, h_0*k_1=1*2=2, det=3-2=1, smaller=2, 2+1=3
        // Step 2 (even): h_2*k_1=7*2=14, h_1*k_2=3*5=15, det=14-15=-1, smaller=14, 14+1=15
        assertMacroExpansion(
            """
            @CFDeterminantProof(coefficients: [1, 2, 2])
            enum Sqrt2Det {}
            """,
            expandedSource: """
            enum Sqrt2Det {

                typealias Chain1x1 = AddOne<Zero>.OneTimesProof

                typealias Chain1x2 = Chain1x1.Distributed

                typealias Chain1x3 = Chain1x2.Distributed

                typealias Chain2x1 = AddOne<AddOne<Zero>>.OneTimesProof

                typealias Chain2x2 = Chain2x1.Distributed

                typealias Chain2x3 = Chain2x2.Distributed

                typealias Chain2x4 = Chain2x3.Distributed

                typealias Chain2x5 = Chain2x4.Distributed

                typealias Chain2x6 = Chain2x5.Distributed

                typealias Chain2x7 = Chain2x6.Distributed

                typealias Chain5x1 = AddOne<AddOne<AddOne<AddOne<AddOne<Zero>>>>>.OneTimesProof

                typealias Chain5x2 = Chain5x1.Distributed

                typealias Chain5x3 = Chain5x2.Distributed

                typealias HTimesPrevK0 = TimesZero<AddOne<Zero>>

                typealias PrevHTimesK0 = Chain1x1

                typealias Determinant0 = PlusSucc<PlusZero<Zero>>

                typealias HTimesPrevK1 = Chain1x3

                typealias PrevHTimesK1 = Chain2x1

                typealias Determinant1 = PlusSucc<PlusZero<AddOne<AddOne<Zero>>>>

                typealias HTimesPrevK2 = Chain2x7

                typealias PrevHTimesK2 = Chain5x3

                typealias Determinant2 = PlusSucc<PlusZero<AddOne<AddOne<AddOne<AddOne<AddOne<AddOne<AddOne<AddOne<AddOne<AddOne<AddOne<AddOne<AddOne<AddOne<Zero>>>>>>>>>>>>>>>>

                func determinantCheck() {
                    assertEqual(Determinant0.Total.self, PrevHTimesK0.Total.self)
                    assertEqual(Determinant1.Total.self, HTimesPrevK1.Total.self)
                    assertEqual(Determinant2.Total.self, PrevHTimesK2.Total.self)
                }
            }
            """,
            macros: cfDeterminantProofMacros
        )
    }

    func testSingleCoefficientProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @CFDeterminantProof(coefficients: [1])
            enum Det {}
            """,
            expandedSource: """
            enum Det {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#CFDeterminantProof requires a coefficients array of at least 2 integer literals >= 1", line: 1, column: 1)
            ],
            macros: cfDeterminantProofMacros
        )
    }

    func testEmptyArrayProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @CFDeterminantProof(coefficients: [])
            enum Det {}
            """,
            expandedSource: """
            enum Det {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#CFDeterminantProof requires a coefficients array of at least 2 integer literals >= 1", line: 1, column: 1)
            ],
            macros: cfDeterminantProofMacros
        )
    }

    func testZeroCoefficientProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @CFDeterminantProof(coefficients: [0, 1])
            enum Det {}
            """,
            expandedSource: """
            enum Det {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#CFDeterminantProof requires a coefficients array of at least 2 integer literals >= 1", line: 1, column: 1)
            ],
            macros: cfDeterminantProofMacros
        )
    }

    #endif
}
