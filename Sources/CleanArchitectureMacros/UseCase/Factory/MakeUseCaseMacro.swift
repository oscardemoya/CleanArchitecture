//
//  MakeUseCaseMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct MakeUseCaseMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract the repository protocol types and use case type (e.g., <AuthRepository, LoginUseCase>)
        guard let genericArguments = node.genericArgumentClause?.arguments, genericArguments.count == 2,
              let repositoryTypes = genericArguments.first,
              let useCaseType = genericArguments.last?.argument.description else {
            let diagnostic = Diagnostic(
                node: node,
                message: MakeUseCaseDiagnostic.invalidArguments
            )
            context.diagnose(diagnostic)
            return []
        }
        
        var properties = [(name: String, type: String)]()
        if let composition = repositoryTypes.argument.as(CompositionTypeSyntax.self) {
            let types = composition.elements.compactMap { $0.type.description.trimmed }
            properties = types.map { (name: $0.asVariableName, type: $0) }
        } else if let argument = repositoryTypes.argument.as(IdentifierTypeSyntax.self) {
            let type = argument.description.trimmed
            properties = [(name: type.asVariableName, type: type)]
        }
        
        guard !properties.isEmpty else {
            let diagnostic = Diagnostic(
                node: node,
                message: MakeUseCaseDiagnostic.noRepositoryProtocol
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let repositoryInits = properties
            .map { "let \($0.name) = repositoryFactory.make\($0.type)()"}
            .joined(separator: "\n    ")
        
        // Extract the concrete repository implementation (e.g., DefaultAuthUseCase)
        let funcArgs = properties.map { "\($0.name): \($0.name)" }.joined(separator: ", ")
        
        // Generate the factory struct code
        let factoryDecl = """
        public func make\(useCaseType)() -> \(useCaseType) {
            \(repositoryInits)
            return \(useCaseType)(\(funcArgs))
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let factoryStructSyntax = DeclSyntax(stringLiteral: factoryDecl)
        
        return [factoryStructSyntax]
    }
}
