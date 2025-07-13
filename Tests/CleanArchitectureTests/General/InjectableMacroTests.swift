import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let initializableTestMacros: [String: Macro.Type] = [
    "Injectable": InjectableMacro.self
]
#endif

final class InjectableMacroTests: XCTestCase {
    func testInjectable_withSingleProtocol() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            @Injectable<AuthRepository>
            struct EmailLoginUseCase {                
                func execute(credentials: LoginCredentials) async throws -> AuthToken {
                    try await authRepository.login(credentials: credentials)
                }
            }
            """,
            expandedSource: """
            struct EmailLoginUseCase {                
                func execute(credentials: LoginCredentials) async throws -> AuthToken {
                    try await authRepository.login(credentials: credentials)
                }

                private let authRepository: AuthRepository

                public init(
                    authRepository: AuthRepository
                ) {
                    self.authRepository = authRepository
                }
            }
            """,
            macros: initializableTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testInjectable_withMultipleProtocol() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            @Injectable<AuthRepository & TokenRepository>
            struct EmailLoginUseCase {                
                func execute(credentials: LoginCredentials) async throws -> AuthToken {
                    let token = try await authRepository.login(credentials: credentials)
                    try tokenRepository.save(token: token)
                    return token
                }
            }
            """,
            expandedSource: """
            struct EmailLoginUseCase {                
                func execute(credentials: LoginCredentials) async throws -> AuthToken {
                    let token = try await authRepository.login(credentials: credentials)
                    try tokenRepository.save(token: token)
                    return token
                }

                private let authRepository: AuthRepository

                private let tokenRepository: TokenRepository

                public init(
                    authRepository: AuthRepository,
                    tokenRepository: TokenRepository
                ) {
                    self.authRepository = authRepository
                    self.tokenRepository = tokenRepository
                }
            }
            """,
            macros: initializableTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

