import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let serviceTestMacros: [String: Macro.Type] = [
    "Service": ServiceMacro.self
]
#endif

final class ServiceMacroTests: XCTestCase {
    func testMacro() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            @Service
            final class ProfileService: @unchecked Sendable, ObservableObject {
                private var fetchCurrentUserUseCase: FetchCurrentUserUseCase
            }
            """,
            expandedSource: """
            final class ProfileService: @unchecked Sendable, ObservableObject {
                private var fetchCurrentUserUseCase: FetchCurrentUserUseCase

                static let shared = ProfileService()

                private init() {
                    self.fetchCurrentUserUseCase = UseCaseFactory.makeFetchCurrentUserUseCase()
                }
            }
            """,
            macros: serviceTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

