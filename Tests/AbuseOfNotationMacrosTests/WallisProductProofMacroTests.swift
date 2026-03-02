import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AbuseOfNotationMacros)
import AbuseOfNotationMacros

nonisolated(unsafe) let wallisProductProofMacros: [String: Macro.Type] = [
    "WallisProductProof": WallisProductProofMacro.self,
]
#endif

final class WallisProductProofMacroTests: XCTestCase {
    #if canImport(AbuseOfNotationMacros)

    func testDepthOne() throws {
        // Depth 1: W_0 = 1/1, W_1 = 4/3
        // Factor correspondence: (2*1-1)(2*1+1) + 1 = (2*1)^2, i.e. 3 + 1 = 4
        assertMacroExpansion(
            """
            @WallisProductProof(depth: 1)
            enum WallisProof {}
            """,
            expandedSource: """
            enum WallisProof {

                typealias Wallis0 = WallisBase

                typealias Wallis1 = WallisStep<Wallis0, AddOne<AddOne<Zero>>.OneTimesProof, AddOne<AddOne<Zero>>.OneTimesProof.Distributed, AddOne<Zero>.OneTimesProof, AddOne<AddOne<AddOne<Zero>>>.OneTimesProof>

                typealias WallisFactor1 = PlusSucc<PlusZero<AddOne<AddOne<AddOne<Zero>>>>>

                func wallisFactorCheck() {
                    assertEqual(WallisFactor1.Total.self, AddOne<AddOne<AddOne<AddOne<Zero>>>>.self)
                }
            }
            """,
            macros: wallisProductProofMacros
        )
    }

    func testZeroProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @WallisProductProof(depth: 0)
            enum WallisProof {}
            """,
            expandedSource: """
            enum WallisProof {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#wallisProductProof requires an integer literal >= 1", line: 1, column: 1)
            ],
            macros: wallisProductProofMacros
        )
    }

    #endif
}
