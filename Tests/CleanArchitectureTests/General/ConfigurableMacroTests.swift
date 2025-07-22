import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CleanArchitectureMacros)
@testable import CleanArchitectureMacros

let configurableTestMacros: [String: Macro.Type] = [
    "Configurable": ConfigurableMacro.self
]
#endif

final class ConfigurableMacroTests: XCTestCase {
    func testConfigurable_withSingleType() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            @Configurable<RemoteDataSourceConfig>
            final class DefaultAuthDataSource: AuthDataSource {
            }
            """,
            expandedSource: """
            final class DefaultAuthDataSource: AuthDataSource {

                let configuration: RemoteDataSourceConfig

                public init(configuration: RemoteDataSourceConfig) {
                    self.configuration = configuration
                }
            }
            """,
            macros: configurableTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testConfigurable_withSingleProtocol() throws {
        #if canImport(CleanArchitectureMacros)
        assertMacroExpansion(
            """
            @Configurable<any DataSourceConfig>
            final class DefaultAuthDataSource: AuthDataSource {
            }
            """,
            expandedSource: """
            final class DefaultAuthDataSource: AuthDataSource {

                let configuration: any DataSourceConfig

                public init(configuration: any DataSourceConfig) {
                    self.configuration = configuration
                }
            }
            """,
            macros: configurableTestMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
