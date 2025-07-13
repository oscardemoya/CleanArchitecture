//
//  AttributeSyntax+TypeCheck.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/13.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

extension AttributeSyntax {
    func classDeclSyntax(providingMembersOf declaration: some DeclGroupSyntax,
                         in context: some MacroExpansionContext) -> ClassDeclSyntax? {
        
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            
            // Check if the macro is applied to a struct
            if let structDecl = declaration.as(StructDeclSyntax.self) {
                
                // Add a FixIt to suggest replacing `class` with `struct`
                let fixIt = FixIt(
                    message: MacroFixItMessage.replaceStructWithClass,
                    changes: [
                        FixIt.Change.replace(
                            oldNode: Syntax(structDecl.structKeyword),
                            newNode: Syntax(TokenSyntax.keyword(.class))
                        )
                    ]
                )
                
                // Attach the diagnostic with the FixIt to the context
                let diagnostic = Diagnostic(
                    node: self,
                    message: MacroDiagnostic.notAClass,
                    fixIts: [fixIt]
                )
                context.diagnose(diagnostic)
                return nil
            }
            
            let diagnostic = Diagnostic(
                node: self,
                message: MacroDiagnostic.notAClass
            )
            context.diagnose(diagnostic)
            return nil
        }
        
        return classDecl
    }
}
