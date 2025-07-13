//
//  InjectableMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/12.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct InjectableMacro: MemberMacro {
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
                message: InjectableDiagnostic.noInitTypes
            )
            context.diagnose(diagnostic)
            return []
        }
        
        var properties = [(name: String, type: String)]()
        if let composition = genericArgument.argument.as(CompositionTypeSyntax.self) {
            let types = composition.elements.compactMap { $0.type.description.trimmed }
            properties = types.map { (name: $0.asVariableName, type: $0) }
        } else if let argument = genericArgument.argument.as(IdentifierTypeSyntax.self) {
            let type = argument.description.trimmed
            properties = [(name: type.asVariableName, type: type)]
        }
        
        guard !properties.isEmpty else {
            let diagnostic = Diagnostic(
                node: node,
                message: InjectableDiagnostic.noInitTypes
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Create the private init method with the generated assignments
        let initArgs = properties.map { "\($0.name): \($0.type)" }.joined(separator: ",\n    ")
        let initAssignments = properties.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n    ")
        let initCode = """
        public init(
            \(initArgs)
        ) {
            \(initAssignments)
        }
        """
        
        // Parse the generated source code into SwiftSyntax
        var declSyntaxList = properties.map { DeclSyntax(stringLiteral: "private let \($0.name): \($0.type)") }
        let initCodeSyntax = DeclSyntax(stringLiteral: initCode)
        declSyntaxList.append(initCodeSyntax)
        return declSyntaxList
    }
}
