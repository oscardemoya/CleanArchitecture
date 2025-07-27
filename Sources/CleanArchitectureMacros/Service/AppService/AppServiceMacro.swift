//
//  AppServiceMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct AppServiceMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Ensure the macro is applied to a class
        guard let classDecl = node.classDeclSyntax(providingMembersOf: declaration, in: context) else {
            return []
        }
        
        // Extract the use case factory type (e.g., UseCaseFactory)
        let classAttributes = classDecl.attributes.compactMap { $0.as(AttributeSyntax.self) }
        let classAttributeIDs = classAttributes.compactMap { $0.attributeName.as(IdentifierTypeSyntax.self) }
        guard let identifier = classAttributeIDs.first(where: { $0.name.text == "AppService" }),
              let useCaseFactoryType = identifier.genericArgumentClause?.arguments.first?.description else {
            let diagnostic = Diagnostic(
                node: node,
                message: AppServiceDiagnostic.noUseCaseFactoryType
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Extract property declarations from the struct
        let properties = classDecl.memberBlock.members.compactMap { member -> (name: String, type: String)? in
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                return nil
            }
            guard let binding = variableDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                  let type = binding.typeAnnotation?.type else {
                return nil
            }
            return (name: identifier.identifier.text, type: type.description)
        }
        
        // Generate factory initialization for use cases
        let useCaseInitAssignments = properties.compactMap { property -> String? in
            guard property.type.localizedCaseInsensitiveContains("UseCase") else { return nil }
            return "self.\(property.name) = useCaseFactory.make\(property.type)()"
        }.joined(separator: "\n")
        
        // Create the private init method with the generated assignments
        let initCode = """
        init(useCaseFactory: \(useCaseFactoryType)) {
            \(useCaseInitAssignments)
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let initCodeSyntax = DeclSyntax(stringLiteral: initCode)
        
        return [initCodeSyntax]
    }
}
