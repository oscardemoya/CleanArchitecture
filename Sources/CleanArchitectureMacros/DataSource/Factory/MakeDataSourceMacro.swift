//
//  MakeDataSourceMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct MakeDataSourceMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract the datasource protocol and config type (e.g., <AuthDataSource, RemoteDataSourceConfig>)
        guard let genericArguments = node.genericArgumentClause?.arguments, genericArguments.count == 2,
              let dataSourceArgument = genericArguments.first?.argument.as(SomeOrAnyTypeSyntax.self),
              let configurationType = genericArguments.last?.argument.description else {
            let diagnostic = Diagnostic(
                node: node,
                message: MakeDataSourceDiagnostic.invalidArguments
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let returnProtocolType = dataSourceArgument.description
        let dataSourceProtocol = dataSourceArgument.constraint.description
        let dataSourceType = "Default\(dataSourceProtocol)"
        guard dataSourceArgument.someOrAnySpecifier.tokenKind == TokenKind.keyword(.any) else {
            let diagnostic = Diagnostic(
                node: node,
                message: MakeDataSourceDiagnostic.missingAnyKeyword
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Generate the factory struct code
        let factoryDecl = """
        func make\(dataSourceProtocol)() -> \(returnProtocolType) {
            \(dataSourceType)(configuration: \(configurationType.asVariableName))
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let factoryStructSyntax = DeclSyntax(stringLiteral: factoryDecl)
        
        return [factoryStructSyntax]
    }
}
