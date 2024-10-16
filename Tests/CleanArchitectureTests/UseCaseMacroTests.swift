import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let useCaseTestMacros: [String: Macro.Type] = [
    "UseCase": UseCaseMacro.self
]
#endif

final class UseCaseMacroTests: XCTestCase {
    func testMacro() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            @UseCase
            struct EmailLogin {
                let authRepository: AuthRepository
                let profileRepository: ProfileRepository
                
                func execute(email: String, password: String) async throws -> User {
                    var user = try await authRepository.logIn(email: email, password: password)
                    user.profile = try await profileRepository.profile(for: user)
                    return user
                }
            }
            """,
            expandedSource: """
            struct EmailLogin {
                let authRepository: AuthRepository
                let profileRepository: ProfileRepository
                
                func execute(email: String, password: String) async throws -> User {
                    var user = try await authRepository.logIn(email: email, password: password)
                    user.profile = try await profileRepository.profile(for: user)
                    return user
                }
            }

            public protocol EmailLoginUseCase {
                func execute(email: String, password: String) async throws -> User
            }

            class EmailLoginDefaultUseCase: EmailLoginUseCase {
                let authRepository: AuthRepository
                let profileRepository: ProfileRepository
                let useCase: EmailLogin

                init(authRepository: AuthRepository, profileRepository: ProfileRepository) {
                    self.authRepository = authRepository
                    self.profileRepository = profileRepository
                    self.useCase = EmailLogin(authRepository: authRepository, profileRepository: profileRepository)
                }

                func execute(email: String, password: String) async throws -> User {
                    try await useCase.execute(email: email, password: password)
                }
            }

            public struct EmailLoginFactory {
                public static func makeUseCase(authRepository: AuthRepository, profileRepository: ProfileRepository) -> EmailLoginUseCase {
                    EmailLoginDefaultUseCase(authRepository: authRepository, profileRepository: profileRepository)
                }
            }
            """,
            macros: useCaseTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
