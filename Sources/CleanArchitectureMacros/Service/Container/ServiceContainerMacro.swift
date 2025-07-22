//
//  ServiceContainerMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct ServiceContainerMacro: MemberMacro, PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let classDecl = node.classDeclSyntax(providingMembersOf: declaration, in: context) else {
            return []
        }
        
        // Generate the use case factory property
        let useCaseFactoryInstance = "let useCaseFactory = UseCaseFactory()"

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
        let serviceInitAssignments = properties.compactMap { property -> String? in
            guard property.name.localizedCaseInsensitiveContains("Service") else { return nil }
            return "self.\(property.name) = Default\(property.type)(useCaseFactory: useCaseFactory)"
        }.joined(separator: "\n")
        
        // Create the private init method with the generated assignments
        let initCode = """
        init(environment: AppEnvironment) {
            \(useCaseFactoryInstance)
            \(serviceInitAssignments)
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let initCodeSyntax = DeclSyntax(stringLiteral: initCode)
        
        return [initCodeSyntax]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            return []
        }
        
        let className = classDecl.name.text
        
        // Extract service properties
        let properties = classDecl.memberBlock.members.compactMap { member -> (name: String, type: String)? in
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = variableDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                  let type = binding.typeAnnotation?.type else {
                return nil
            }
            return (name: identifier.identifier.text, type: type.description)
        }
        
        let serviceProperties = properties.filter { $0.name.hasSuffix("Service") }
        
        // Generate environment assignments
        let environmentAssignments = serviceProperties.map { property in
            ".environment(\\.\(property.name), serviceContainer.\(property.name))"
        }.joined(separator: "\n            ")
        
        // Create ViewModifier
        let viewModifierCode = """
        struct ServiceContainerModifier: ViewModifier {
            let serviceContainer = \(className)(environment: .current)
            
            func body(content: Content) -> some View {
                content
                    \(environmentAssignments)
            }
        }
        """
        
        return [DeclSyntax(stringLiteral: viewModifierCode)]
    }
}
