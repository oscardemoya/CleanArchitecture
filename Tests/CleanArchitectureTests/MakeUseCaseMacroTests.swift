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
    func testMacro() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            struct UseCaseFactory {
                #MakeUseCase<AuthRepository & ProfileRepository>(FetchCurrentUserUseCase)
            }
            """,
            expandedSource: """
            struct UseCaseFactory {
                public static func makeFetchCurrentUserUseCase() -> FetchCurrentUserUseCase {
                    let authRepository = RepositoryFactory.makeAuthRepository()
                    let profileRepository = RepositoryFactory.makeProfileRepository()
                    return FetchCurrentUserFactory.makeUseCase(authRepository: authRepository, profileRepository: profileRepository)
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

