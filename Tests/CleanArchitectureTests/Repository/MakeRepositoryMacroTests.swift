import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let makeRepositoryTestMacros: [String: Macro.Type] = [
    "MakeRepository": MakeRepositoryMacro.self
]
#endif

final class MakeRepositoryMacroTests: XCTestCase {
    func testMakeRepository() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            struct RepositoryFactory {
                #MakeRepository<AuthRepository>()
            }
            """,
            expandedSource: """
            struct RepositoryFactory {
                public func makeAuthRepository() -> AuthRepository {
                    let authDataSource = dataSourceFactory.makeAuthDataSource()
                    return DefaultAuthRepository(authDataSource: authDataSource)
                }
            }
            """,
            macros: makeRepositoryTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
