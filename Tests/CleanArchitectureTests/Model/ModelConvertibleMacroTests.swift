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
    
    func testModelConvertibleWithOptionals() {
        assertMacroExpansion(
            """
            @ModelConvertible
            struct UserData {
                @Convertible(key: "username")
                let email: String
                let firstName: String?
                let lastName: String?
            }
            """,
            expandedSource: """
            struct UserData {
                let email: String
                let firstName: String?
                let lastName: String?

                var asDomainEntity: User {
                    .init(
                        username: email,
                        firstName: firstName,
                        lastName: lastName
                    )
                }

                init(email: String, firstName: String? = nil, lastName: String? = nil) {
                    self.email = email
                    self.firstName = firstName
                    self.lastName = lastName
                }

                init(entity: User) {
                    self.init(
                        email: entity.username,
                        firstName: entity.firstName,
                        lastName: entity.lastName
                    )
                }
            }
            """,
            macros: makeModelConvertibleTestMacros
        )
    }
}
