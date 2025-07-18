import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let makeModelConvertibleTestMacros: [String: Macro.Type] = [
    "ModelConvertible": ModelConvertibleMacro.self,
    "Convertible": ConvertibleMacro.self
]
#endif

final class ModelConvertibleMacroTests: XCTestCase {
    func testModelConvertible() {
        assertMacroExpansion(
            """
            @ModelConvertible
            struct LoginCredentialsData {
                @Convertible(key: "username")
                let email: String
                let password: String
            }
            """,
            expandedSource: """
            struct LoginCredentialsData {
                let email: String
                let password: String

                var asDomainEntity: LoginCredentials {
                    .init(
                        username: email,
                        password: password
                    )
                }

                init(email: String, password: String) {
                    self.email = email
                    self.password = password
                }

                init(entity: LoginCredentials) {
                    self.init(
                        email: entity.username,
                        password: entity.password
                    )
                }
            }
            """,
            macros: makeModelConvertibleTestMacros
        )
    }
}
