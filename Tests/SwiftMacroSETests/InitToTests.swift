import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftMacroSEMacros


final class InitToTests: XCTestCase {

    let testMacros: [String: Macro.Type] = [
        "InitTo": InitTo.self,
    ]

    func testAddInitMacro() {
        assertMacroExpansion(
            """
            @InitTo
            struct T {
                let t1: Int?
                let t2: Float
            }
            """,
            expandedSource:
            """

            struct T {
                let t1: Int?
                let t2: Float
                init(t1: Int? = nil, t2: Float) {
                    self.t1 = t1
                    self.t2 = t2
                }
            }
            """,
            macros: testMacros
        )
    }

    func testAddPublicInitMacro() {
        assertMacroExpansion(
            """
            @InitTo
            public class T {
                let t1: Int?
                let t2: String
            }
            """,
            expandedSource:
            """

            public class T {
                let t1: Int?
                let t2: String
                public init(t1: Int? = nil, t2: String) {
                    self.t1 = t1
                    self.t2 = t2
                }
            }
            """,
            macros: testMacros
        )
    }

}
