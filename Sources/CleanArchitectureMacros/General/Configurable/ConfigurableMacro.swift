//
//  ConfigurableMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/12.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct ConfigurableMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract the datasource config types (e.g., RemoteDataSourceConfig)
        guard let identifier = node.attributeName.as(IdentifierTypeSyntax.self),
              let genericArgument = identifier.genericArgumentClause?.arguments.first else {
            let diagnostic = Diagnostic(
                node: node,
                message: ConfigurableDiagnostic.noConfigurationType
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Ensure the generic argument has only one type argument
        guard genericArgument.argument.as(CompositionTypeSyntax.self) == nil else {
            let diagnostic = Diagnostic(
                node: node,
                message: ConfigurableDiagnostic.noMultipleConfigurationTypes
            )
            context.diagnose(diagnostic)
            return []
        }
        
        var configuration: (name: String, type: String)?
        if let argument = genericArgument.argument.as(IdentifierTypeSyntax.self) {
            let type = argument.description.trimmed
            configuration = (name: type.asVariableName, type: type)
        } else if let argument = genericArgument.argument.as(SomeOrAnyTypeSyntax.self) {
            let name = argument.constraint.description.asVariableName
            let type = argument.description.trimmed
            configuration = (name: name, type: type)
        }
        
        guard let configuration else {
            let diagnostic = Diagnostic(
                node: node,
                message: ConfigurableDiagnostic.noConfigurationType
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Create the private init method with the generated assignments
        let initCode = """
        public init(configuration: \(configuration.type)) {
            self.configuration = configuration
        }
        """
        
        // Parse the generated source code into SwiftSyntax
        let configMemberSyntax = DeclSyntax(stringLiteral: "let configuration: \(configuration.type)")
        let initCodeSyntax = DeclSyntax(stringLiteral: initCode)
        return [configMemberSyntax, initCodeSyntax]
    }
}
