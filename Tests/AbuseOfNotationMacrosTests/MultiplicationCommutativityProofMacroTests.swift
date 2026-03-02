import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AbuseOfNotationMacros)
import AbuseOfNotationMacros

nonisolated(unsafe) let multiplicationCommutativityProofMacros: [String: Macro.Type] = [
    "MultiplicationCommutativityProof": MultiplicationCommutativityProofMacro.self,
]
#endif

final class MultiplicationCommutativityProofMacroTests: XCTestCase {
    #if canImport(AbuseOfNotationMacros)

    func testLeftOperandTwoDepthTwo() throws {
        assertMacroExpansion(
            """
            @MultiplicationCommutativityProof(leftOperand: 2, depth: 2)
            enum MulComm2 {}
            """,
            expandedSource: """
            enum MulComm2 {

                typealias Forward0 = TimesZero<AddOne<AddOne<Zero>>>

                typealias Reverse0 = AddOne<AddOne<Zero>>.ZeroTimesProof

                typealias Forward1 = TimesGroup<TimesTick<TimesTick<Forward0>>>

                typealias Reverse1 = Reverse0.Distributed

                typealias Forward2 = TimesGroup<TimesTick<TimesTick<Forward1>>>

                typealias Reverse2 = Reverse1.Distributed
            }
            """,
            macros: multiplicationCommutativityProofMacros
        )
    }

    func testLeftOperandThreeDepthOne() throws {
        assertMacroExpansion(
            """
            @MultiplicationCommutativityProof(leftOperand: 3, depth: 1)
            enum MulComm3 {}
            """,
            expandedSource: """
            enum MulComm3 {

                typealias Forward0 = TimesZero<AddOne<AddOne<AddOne<Zero>>>>

                typealias Reverse0 = AddOne<AddOne<AddOne<Zero>>>.ZeroTimesProof

                typealias Forward1 = TimesGroup<TimesTick<TimesTick<TimesTick<Forward0>>>>

                typealias Reverse1 = Reverse0.Distributed
            }
            """,
            macros: multiplicationCommutativityProofMacros
        )
    }

    func testZeroLeftOperandProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @MultiplicationCommutativityProof(leftOperand: 0, depth: 3)
            enum MulComm0 {}
            """,
            expandedSource: """
            enum MulComm0 {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#MultiplicationCommutativityProof requires an integer literal >= 2", line: 1, column: 1)
            ],
            macros: multiplicationCommutativityProofMacros
        )
    }

    func testOneLeftOperandProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @MultiplicationCommutativityProof(leftOperand: 1, depth: 3)
            enum MulComm1 {}
            """,
            expandedSource: """
            enum MulComm1 {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#MultiplicationCommutativityProof requires an integer literal >= 2", line: 1, column: 1)
            ],
            macros: multiplicationCommutativityProofMacros
        )
    }

    #endif
}
