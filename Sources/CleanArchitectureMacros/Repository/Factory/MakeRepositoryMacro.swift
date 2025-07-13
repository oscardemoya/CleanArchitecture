//
//  MakeRepositoryMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct MakeRepositoryMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract the repository protocol type (e.g., AuthRepository)
        guard let repositoryType = node.genericArgumentClause?.arguments.first else {
            let diagnostic = Diagnostic(
                node: node,
                message: MakeRepositoryDiagnostic.noRepositoryProtocol
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Extract the concrete repository implementation (e.g., DefaultAuthRepository)
        let returnType = node.arguments.first?.expression ?? "Default\(repositoryType)"
        let repositoryEntity = repositoryType.description.replacingOccurrences(of: "Repository", with: "")
        let datasourceType = "\(repositoryEntity)DataSource"
        let datasourceArg = datasourceType.asVariableName
        
        // Generate the factory struct code
        let factoryDecl = """
        public func make\(repositoryType)() -> \(repositoryType) {
            let \(datasourceArg) = dataSourceFactory.make\(datasourceType)()
            return \(returnType)(\(datasourceArg): \(datasourceArg))
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let factoryStructSyntax = DeclSyntax(stringLiteral: factoryDecl)
        
        return [factoryStructSyntax]
    }
}
