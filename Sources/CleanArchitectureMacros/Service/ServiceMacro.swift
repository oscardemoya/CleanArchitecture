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

struct ServiceMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Ensure the macro is applied to a class
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            
            // Check if the macro is applied to a struct
            if let structDecl = declaration.as(StructDeclSyntax.self) {
                
                // Add a FixIt to suggest replacing `class` with `struct`
                let fixIt = FixIt(
                    message: ServiceFixItMessage.replaceStructWithClass,
                    changes: [
                        FixIt.Change.replace(
                            oldNode: Syntax(structDecl.structKeyword),
                            newNode: Syntax(TokenSyntax.keyword(.class))
                        )
                    ]
                )
                
                // Attach the diagnostic with the FixIt to the context
                let diagnostic = Diagnostic(
                    node: node,
                    message: ServiceDiagnostic.notAClass,
                    fixIts: [fixIt]
                )
                context.diagnose(diagnostic)
                
                return []
            }
            
            let diagnostic = Diagnostic(
                node: node,
                message: UseCaseDiagnostic.notAStruct
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
        
        // Generate the static shared instance
        let sharedInstance = "static let shared = \(classDecl.name.text)()"
        
        // Generate factory initialization for use cases
        let useCaseInitAssignments = properties.compactMap { property -> String? in
            guard property.name.localizedCaseInsensitiveContains("UseCase") else { return nil }
            return "self.\(property.name) = UseCaseFactory.make\(property.type)()"
        }.joined(separator: "\n")
        
        // Create the private init method with the generated assignments
        let initCode = """
        private init() {
            \(useCaseInitAssignments)
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let sharedInstanceSyntax = DeclSyntax(stringLiteral: sharedInstance)
        let initCodeSyntax = DeclSyntax(stringLiteral: initCode)
        
        return [sharedInstanceSyntax, initCodeSyntax]
    }
}

