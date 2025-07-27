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
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let dependencyProperties = parseDependencyProperties(from: node)
        
        guard !dependencyProperties.isEmpty else {
            let diagnostic = Diagnostic(
                node: node,
                message: InjectableDiagnostic.noInitTypes
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let existingProperties = extractExistingProperties(from: declaration)
        
        return makeMemberDecls(dependencyProperties: dependencyProperties, existingProperties: existingProperties)
    }
    
    private static func parseDependencyProperties(from node: AttributeSyntax) -> [(name: String, type: String)] {
        guard let identifier = node.attributeName.as(IdentifierTypeSyntax.self),
              let genericArgument = identifier.genericArgumentClause?.arguments.first else {
            return []
        }
        
        var dependencyProperties = [(name: String, type: String)]()
        if let composition = genericArgument.argument.as(CompositionTypeSyntax.self) {
            let types = composition.elements.compactMap { $0.type.description.trimmed }
            dependencyProperties = types.map { (name: $0.asVariableName, type: $0) }
        } else if let argument = genericArgument.argument.as(IdentifierTypeSyntax.self) {
            let type = argument.description.trimmed
            dependencyProperties = [(name: type.asVariableName, type: type)]
        } else if let argument = genericArgument.argument.as(SomeOrAnyTypeSyntax.self) {
            let name = argument.constraint.description.asVariableName
            let type = argument.description.trimmed
            dependencyProperties = [(name: name, type: type)]
        }
        
        return dependencyProperties
    }
    
    private static func extractExistingProperties(
        from declaration: some DeclGroupSyntax
    ) -> [(name: String, type: String)] {
        var existingProperties = [(name: String, type: String)]()
        for member in declaration.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                if variableDecl.bindingSpecifier.tokenKind == .keyword(.let) {
                    for binding in variableDecl.bindings {
                        if let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                           let typeAnnotation = binding.typeAnnotation?.type {
                            let propertyName = identifier.identifier.text
                            let propertyType = typeAnnotation.description.trimmed
                            existingProperties.append((name: propertyName, type: propertyType))
                        }
                    }
                }
            }
        }
        return existingProperties
    }
    
    private static func makeMemberDecls(
        dependencyProperties: [(name: String, type: String)],
        existingProperties: [(name: String, type: String)]
    ) -> [DeclSyntax] {
        let allInitProperties = dependencyProperties + existingProperties
        
        var declSyntaxList = dependencyProperties.map {
            DeclSyntax(stringLiteral: "private let \($0.name): \($0.type)")
        }
        
        let initArgs = allInitProperties.map { "\($0.name): \($0.type)" }.joined(separator: ",\n    ")
        let initAssignments = allInitProperties.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n    ")
        
        let initCode = """
        public init(
            \(initArgs)
        ) {
            \(initAssignments)
        }
        """
        
        let initCodeSyntax = DeclSyntax(stringLiteral: initCode)
        declSyntaxList.append(initCodeSyntax)
        
        return declSyntaxList
    }
}
