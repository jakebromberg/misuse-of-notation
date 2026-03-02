import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AbuseOfNotationMacros)
import AbuseOfNotationMacros

nonisolated(unsafe) let productConformanceMacros: [String: Macro.Type] = [
    "ProductConformance": ProductConformanceMacro.self,
]
#endif

final class ProductConformanceMacroTests: XCTestCase {
    #if canImport(AbuseOfNotationMacros)

    func testTimesTwo() throws {
        assertMacroExpansion(
            """
            @ProductConformance(2)
            enum Product<L: Natural, R: Natural> {}
            """,
            expandedSource: """
            enum Product<L: Natural, R: Natural> {}

            protocol TimesN2: Natural {
                associatedtype TimesN2Result: Natural
            }

            extension Zero: TimesN2 {
                typealias TimesN2Result = Zero
            }

            extension AddOne: TimesN2 where Predecessor: TimesN2 {
                typealias TimesN2Result = AddOne<AddOne<Predecessor.TimesN2Result>>
            }

            extension Product where L == AddOne<AddOne<Zero>>, R: TimesN2 {
                typealias Result = R.TimesN2Result
            }
            """,
            macros: productConformanceMacros
        )
    }

    func testTimesThree() throws {
        assertMacroExpansion(
            """
            @ProductConformance(3)
            enum Product<L: Natural, R: Natural> {}
            """,
            expandedSource: """
            enum Product<L: Natural, R: Natural> {}

            protocol TimesN3: Natural {
                associatedtype TimesN3Result: Natural
            }

            extension Zero: TimesN3 {
                typealias TimesN3Result = Zero
            }

            extension AddOne: TimesN3 where Predecessor: TimesN3 {
                typealias TimesN3Result = AddOne<AddOne<AddOne<Predecessor.TimesN3Result>>>
            }

            extension Product where L == AddOne<AddOne<AddOne<Zero>>>, R: TimesN3 {
                typealias Result = R.TimesN3Result
            }
            """,
            macros: productConformanceMacros
        )
    }

    func testZeroProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @ProductConformance(0)
            enum Product<L: Natural, R: Natural> {}
            """,
            expandedSource: """
            enum Product<L: Natural, R: Natural> {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#ProductConformance requires an integer literal >= 2", line: 1, column: 1)
            ],
            macros: productConformanceMacros
        )
    }

    func testOneProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @ProductConformance(1)
            enum Product<L: Natural, R: Natural> {}
            """,
            expandedSource: """
            enum Product<L: Natural, R: Natural> {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "#ProductConformance requires an integer literal >= 2", line: 1, column: 1)
            ],
            macros: productConformanceMacros
        )
    }

    #endif
}
