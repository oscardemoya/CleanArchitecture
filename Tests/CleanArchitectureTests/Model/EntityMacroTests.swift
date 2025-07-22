import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let makeEntityTestMacros: [String: Macro.Type] = [
    "Entity": EntityMacro.self
]
#endif

final class EntityMacroTests: XCTestCase {
    func testEntity() {
        assertMacroExpansion(
            """
            @Entity
            struct LoginCredentials {
                let email: String
                let password: String
            }
            """,
            expandedSource: """
            struct LoginCredentials {
                let email: String
                let password: String

                init(email: String, password: String) {
                    self.email = email
                    self.password = password
                }
            }
            """,
            macros: makeEntityTestMacros
        )
    }
    
    func testEntityWithOptionals() {
        assertMacroExpansion(
            """
            @Entity
            struct LoginCredentials {
                let email: String
                let firstName: String?
                let lastName: String?
            }
            """,
            expandedSource: """
            struct LoginCredentials {
                let email: String
                let firstName: String?
                let lastName: String?

                init(email: String, firstName: String? = nil, lastName: String? = nil) {
                    self.email = email
                    self.firstName = firstName
                    self.lastName = lastName
                }
            }
            """,
            macros: makeEntityTestMacros
        )
    }
}
