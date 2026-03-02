import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AbuseOfNotationMacros)
import AbuseOfNotationMacros

nonisolated(unsafe) let fibonacciProofMacros: [String: Macro.Type] = [
    "FibonacciProof": FibonacciProofMacro.self,
]
#endif

final class FibonacciProofMacroTests: XCTestCase {
    #if canImport(AbuseOfNotationMacros)

    func testUpToOne() throws {
        assertMacroExpansion(
            """
            @FibonacciProof(upTo: 1)
            enum FibProof {}
            """,
            expandedSource: """
            enum FibProof {

                typealias FibonacciWitness1 = PlusSucc<PlusZero<Zero>>

                typealias Fibonacci1 = FibonacciStep<Fibonacci0, FibonacciWitness1>
            }
            """,
            macros: fibonacciProofMacros
        )
    }

    func testUpToThree() throws {
        assertMacroExpansion(
            """
            @FibonacciProof(upTo: 3)
            enum FibProof {}
            """,
            expandedSource: """
            enum FibProof {

                typealias FibonacciWitness1 = PlusSucc<PlusZero<Zero>>

                typealias Fibonacci1 = FibonacciStep<Fibonacci0, FibonacciWitness1>

                typealias FibonacciWitness2 = PlusSucc<PlusZero<AddOne<Zero>>>

                typealias Fibonacci2 = FibonacciStep<Fibonacci1, FibonacciWitness2>

                typealias FibonacciWitness3 = PlusSucc<PlusSucc<PlusZero<AddOne<Zero>>>>

                typealias Fibonacci3 = FibonacciStep<Fibonacci2, FibonacciWitness3>
            }
            """,
            macros: fibonacciProofMacros
        )
    }

    func testZeroProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @FibonacciProof(upTo: 0)
            enum FibProof {}
            """,
            expandedSource: """
            enum FibProof {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#fibonacciProof requires an integer literal >= 1", line: 1, column: 1)
            ],
            macros: fibonacciProofMacros
        )
    }

    #endif
}
