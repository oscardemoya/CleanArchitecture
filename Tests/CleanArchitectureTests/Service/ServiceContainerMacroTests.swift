import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let serviceContainerTestMacros: [String: Macro.Type] = [
    "ServiceContainer": ServiceContainerMacro.self
]
#endif

final class ServiceContainerMacroTests: XCTestCase {
    func testServiceContainer() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            @Observable
            @ServiceContainer
            final class ServiceContainer: ServiceProvider {
                let authService: AuthService
                let profileService: ProfileService
            }
            """,
            expandedSource: """
            @Observable
            final class ServiceContainer: ServiceProvider {
                let authService: AuthService
                let profileService: ProfileService

                init(environment: AppEnvironment) {
                    let useCaseFactory = UseCaseFactory()
                    self.authService = DefaultAuthService(useCaseFactory: useCaseFactory)
                    self.profileService = DefaultProfileService(useCaseFactory: useCaseFactory)
                }
            }
            """,
            macros: serviceContainerTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

