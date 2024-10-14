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
        
        // Extract the repository protocol type (e.g., AuthUseCase)
        guard let reposityList = node.genericArgumentClause?.arguments.first?.description else {
            let diagnostic = Diagnostic(
                node: node,
                message: MakeUseCaseDiagnostic.noRepositoryProtocol
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let repositoryTypes: [String] = reposityList
            .split(separator: "&")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        guard let useCaseType = node.arguments.first else {
            let diagnostic = Diagnostic(
                node: node,
                message: MakeUseCaseDiagnostic.noRepositoryProtocol
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let useCaseName = useCaseType.description.replacingOccurrences(of: "UseCase", with: "")
        
        let repositoryInits = repositoryTypes.map {
            let argName = $0.description.lowercasingFirstLetter()
            let argType = $0.description
            return "let \(argName) = RepositoryFactory.make\(argType)()"
        }.joined(separator: "\n    ")
        
        // Extract the concrete repository implementation (e.g., DefaultAuthUseCase)
        let funcArgs = repositoryTypes.map {
            let argName = $0.description.lowercasingFirstLetter()
            return "\(argName): \(argName)"
        }.joined(separator: ", ")
        
        // Generate the factory struct code
        let factoryStructName = "\(useCaseName)Factory"
        let factoryDecl = """
        public static func make\(useCaseType)() -> \(useCaseType) {
            \(repositoryInits)
            return \(factoryStructName).makeUseCase(\(funcArgs))
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let factoryStructSyntax = DeclSyntax(stringLiteral: factoryDecl)
        
        return [factoryStructSyntax]
    }
}

extension String {
    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }

    mutating func lowercasingFirstLetter() {
        self = self.lowercasingFirstLetter()
    }
}
