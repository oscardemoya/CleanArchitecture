//
//  ModelConvertible+ValidationHelper.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/18.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

extension ModelConvertibleMacro {
    struct ValidationHelper {
        static func validateStructDeclaration(
            _ node: AttributeSyntax,
            _ declaration: some DeclGroupSyntax,
            _ context: some MacroExpansionContext
        ) -> StructDeclSyntax? {
            guard let structDecl = declaration.as(StructDeclSyntax.self) else {
                let diagnostic = Diagnostic(
                    node: node,
                    message: ModelConvertibleDiagnostic.notAStruct
                )
                context.diagnose(diagnostic)
                return nil
            }
            return structDecl
        }
        
        static func validateStructNaming(
            _ node: AttributeSyntax,
            _ structDecl: StructDeclSyntax,
            _ structName: String,
            _ context: some MacroExpansionContext
        ) -> Bool {
            guard structName.hasSuffix("Data") else {
                let diagnostic = Diagnostic(
                    node: structDecl.name,
                    message: ModelConvertibleDiagnostic.invalidNaming,
                    fixIt: FixIt(
                        message: ModelConvertibleFixItMessage.addDataSuffix,
                        changes: [
                            .replace(
                                oldNode: Syntax(structDecl.name),
                                newNode: Syntax(TokenSyntax("\(raw: structName)Data"))
                            )
                        ]
                    )
                )
                context.diagnose(diagnostic)
                return false
            }
            return true
        }
        
        static func reportExistingMembersError(
            _ node: AttributeSyntax,
            _ context: some MacroExpansionContext
        ) {
            let diagnostic = Diagnostic(
                node: node,
                message: ModelConvertibleDiagnostic.existingMember
            )
            context.diagnose(diagnostic)
        }
        
        static func reportMissingPropertiesError(
            _ structDecl: StructDeclSyntax,
            _ context: some MacroExpansionContext
        ) {
            let diagnostic = Diagnostic(
                node: structDecl,
                message: ModelConvertibleDiagnostic.missingProperties
            )
            context.diagnose(diagnostic)
        }
    }
}
