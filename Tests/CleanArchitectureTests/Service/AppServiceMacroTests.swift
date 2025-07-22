import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let appServiceTestMacros: [String: Macro.Type] = [
    "AppService": AppServiceMacro.self
]
#endif

final class AppServiceMacroTests: XCTestCase {
    func testAppService() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            @Observable
            @AppService<UseCaseFactory>
            final class ProfileService {
                private var fetchCurrentUserUseCase: FetchCurrentUserUseCase
            }
            """,
            expandedSource: """
            @Observable
            final class ProfileService {
                private var fetchCurrentUserUseCase: FetchCurrentUserUseCase

                init(useCaseFactory: UseCaseFactory) {
                    self.fetchCurrentUserUseCase = useCaseFactory.makeFetchCurrentUserUseCase()
                }
            }
            """,
            macros: appServiceTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
