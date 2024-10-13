//
//  RepositoryFactoryMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct RepositoryFactoryMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract the repository protocol type (e.g., AuthRepository)
        guard let repositoryType = node.genericArgumentClause?.arguments.first else {
            let diagnostic = Diagnostic(
                node: node,
                message: RepositoryFactoryDiagnostic.noRepositoryProtocol
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Extract the concrete repository implementation (e.g., DefaultAuthRepository)
        let returnType = node.arguments.first?.expression ?? "Default\(repositoryType)"
        
        // Generate the factory struct code
        let factoryDecl = """
        public static func make\(repositoryType)() -> \(repositoryType) {
            \(returnType)()
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let factoryStructSyntax = DeclSyntax(stringLiteral: factoryDecl)
        
        return [factoryStructSyntax]
    }
}
