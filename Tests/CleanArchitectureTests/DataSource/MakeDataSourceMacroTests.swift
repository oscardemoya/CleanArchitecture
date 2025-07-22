import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let makeDataSourceTestMacros: [String: Macro.Type] = [
    "MakeDataSource": MakeDataSourceMacro.self
]
#endif

final class MakeDataSourceMacroTests: XCTestCase {
    func testMakeDataSource() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            struct DataSourceFactory {
                #MakeDataSource<any AuthDataSource, RemoteDataSourceConfig>()
            }
            """,
            expandedSource: """
            struct DataSourceFactory {
                func makeAuthDataSource() -> any AuthDataSource {
                    DefaultAuthDataSource(configuration: remoteDataSourceConfig)
                }
            }
            """,
            macros: makeDataSourceTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
