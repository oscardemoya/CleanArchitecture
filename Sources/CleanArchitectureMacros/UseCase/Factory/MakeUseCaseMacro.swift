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
        guard let genericArguments = node.genericArgumentClause?.arguments,
              genericArguments.count >= 2 else {
            let diagnostic = Diagnostic(
                node: node,
                message: MakeUseCaseDiagnostic.invalidArguments
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let repositoryTypes = genericArguments.first!
        let useCaseType = genericArguments.dropFirst().first!.argument.description.trimmed
        let additionalDependencies = Array(genericArguments.dropFirst(2))
        
        let repositoryProperties = parseRepositoryProperties(from: repositoryTypes)
        guard !repositoryProperties.isEmpty else {
            let diagnostic = Diagnostic(
                node: node,
                message: MakeUseCaseDiagnostic.noRepositoryProtocol
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let useCaseProperties = parseUseCaseProperties(from: additionalDependencies)
        
        let repositoryInits = generateRepositoryInits(from: repositoryProperties)
        let useCaseInits = generateUseCaseInits(from: useCaseProperties)
        let funcArgs = makeFuncArgs(repositoryProperties + useCaseProperties)
        
        let factoryDecl = makeFactoryDecl(for: useCaseType,
                                          repoInits: repositoryInits,
                                          useCaseInits: useCaseInits,
                                          funcArgs: funcArgs)
        
        let factoryFunctionSyntax = DeclSyntax(stringLiteral: factoryDecl)
        
        return [factoryFunctionSyntax]
    }
    
    // MARK: - Private Helpers
    
    private static func parseRepositoryProperties(
        from repositoryTypes: GenericArgumentSyntax
    ) -> [(name: String, type: String)] {
        var repositoryProperties = [(name: String, type: String)]()
        if let composition = repositoryTypes.argument.as(CompositionTypeSyntax.self) {
            let types = composition.elements.compactMap { $0.type.description.trimmed }
            repositoryProperties = types.map { (name: $0.asVariableName, type: $0) }
        } else if let argument = repositoryTypes.argument.as(IdentifierTypeSyntax.self) {
            let type = argument.description.trimmed
            repositoryProperties = [(name: type.asVariableName, type: type)]
        } else if let argument = repositoryTypes.argument.as(SomeOrAnyTypeSyntax.self) {
            let name = argument.constraint.description.asVariableName
            let type = argument.description.trimmed
            repositoryProperties = [(name: name, type: type)]
        }
        return repositoryProperties
    }
    
    private static func parseUseCaseProperties(
        from additionalDependencies: [GenericArgumentSyntax]
    ) -> [(name: String, type: String)] {
        var useCaseProperties = [(name: String, type: String)]()
        for dependency in additionalDependencies {
            let dependencyType = dependency.argument.description.trimmed
            let propertyName = dependencyType.asVariableName
            useCaseProperties.append((name: propertyName, type: dependencyType))
        }
        return useCaseProperties
    }
    
    private static func generateRepositoryInits(from repositoryProperties: [(name: String, type: String)]) -> String {
        repositoryProperties
            .map { "let \($0.name) = repositoryFactory.make\($0.type)()" }
            .joined(separator: "\n    ")
    }
    
    private static func generateUseCaseInits(from useCaseProperties: [(name: String, type: String)]) -> String {
        useCaseProperties
            .map { "let \($0.name) = make\($0.type)()" }
            .joined(separator: "\n    ")
    }
    
    private static func makeFuncArgs(_ properties: [(name: String, type: String)]) -> String {
        properties.map { "\($0.name): \($0.name)" }.joined(separator: ",\n        ")
    }
    
    private static func makeFactoryDecl(
        for useCaseType: String, repoInits: String, useCaseInits: String, funcArgs: String
    ) -> String {
        var allInits = [String]()
        if !repoInits.isEmpty {
            allInits.append(repoInits)
        }
        if !useCaseInits.isEmpty {
            allInits.append(useCaseInits)
        }
        let combinedInits = allInits.joined(separator: "\n    ")
        
        return """
        public func make\(useCaseType)() -> \(useCaseType) {
            \(combinedInits)
            return \(useCaseType)(
                \(funcArgs)
            )
        }
        """
    }
}
