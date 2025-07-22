//
//  ModelConvertible+StructInspector.swift
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
    struct StructInspector {
        static func hasExistingConversionMembers(in structDecl: StructDeclSyntax) -> Bool {
            for member in structDecl.memberBlock.members {
                if let variable = member.decl.as(VariableDeclSyntax.self),
                   let binding = variable.bindings.first,
                   let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                   pattern.identifier.text == "asDomainEntity" {
                    return true
                }
                
                if let initializer = member.decl.as(InitializerDeclSyntax.self),
                   let parameterList = initializer.signature.parameterClause.parameters.first,
                   parameterList.firstName.text == "entity" {
                    return true
                }
            }
            return false
        }
        
        static func hasDefaultInitializer(in structDecl: StructDeclSyntax) -> Bool {
            for member in structDecl.memberBlock.members {
                if let initializer = member.decl.as(InitializerDeclSyntax.self) {
                    let isConvenience = initializer.modifiers.contains { modifier in
                        modifier.name.tokenKind == .keyword(.convenience)
                    }
                    let isFailable = initializer.optionalMark != nil
                    
                    if !isConvenience && !isFailable {
                        return true
                    }
                }
            }
            return false
        }
    }
}
