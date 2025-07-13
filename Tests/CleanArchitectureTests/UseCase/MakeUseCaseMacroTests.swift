import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let makeUseCaseTestMacros: [String: Macro.Type] = [
    "MakeUseCase": MakeUseCaseMacro.self
]
#endif

final class MakeUseCaseMacroTests: XCTestCase {
    func testMakeUseCase() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            struct UseCaseFactory {
                #MakeUseCase<AuthRepository & ProfileRepository, LoginUseCase>()
            }
            """,
            expandedSource: """
            struct UseCaseFactory {
                public func makeLoginUseCase() -> LoginUseCase {
                    let authRepository = repositoryFactory.makeAuthRepository()
                    let profileRepository = repositoryFactory.makeProfileRepository()
                    return LoginUseCase(authRepository: authRepository, profileRepository: profileRepository)
                }
            }
            """,
            macros: makeUseCaseTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

