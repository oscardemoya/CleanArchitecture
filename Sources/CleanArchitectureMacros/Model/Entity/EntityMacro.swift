//
//  EntityMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/16.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct EntityMacro: MemberMacro {
    struct PropertyInfo {
        let name: String
        let type: String
        var isOptional: Bool { type.hasSuffix("?") || type.hasPrefix("Optional<") }
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: EntityDiagnostic.notAStruct
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let properties = extractPropertiesWithTypes(from: structDecl)
        
        if properties.isEmpty {
            let diagnostic = Diagnostic(
                node: structDecl,
                message: EntityDiagnostic.missingProperties
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let accessLevel = extractAccessLevel(from: structDecl)
        let hasDefaultInit = hasDefaultInitializer(in: structDecl)
        
        var members: [DeclSyntax] = []
        
        // Generate default init if needed
        if !hasDefaultInit {
            let defaultInit = DeclSyntax(
                """
                \(raw: accessLevel)init(\(raw: generateDefaultInitParametersWithTypes(for: properties))) {
                    \(raw: generateDefaultInitAssignments(for: properties))
                }
                """
            )
            members.append(defaultInit)
        }
        
        return members
    }
    
    private static func extractPropertiesWithTypes(from structDecl: StructDeclSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []
        
        for member in structDecl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            
            guard variableDecl.bindingSpecifier.tokenKind == .keyword(.let) ||
                  variableDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
                continue
            }
            
            guard variableDecl.bindings.allSatisfy({ $0.accessorBlock == nil }) else {
                continue
            }
            
            for binding in variableDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }
                
                let propertyName = pattern.identifier.text
                
                // Get the type
                let typeDescription = binding.typeAnnotation?
                    .type.description.trimmingCharacters(in: .whitespaces) ?? "Any"
                
                properties.append(PropertyInfo(
                    name: propertyName,
                    type: typeDescription
                ))
            }
        }
        
        return properties
    }
    
    private static func generateDefaultInitParametersWithTypes(for properties: [PropertyInfo]) -> String {
        properties
            .map { "\($0.name): \($0.type)\($0.isOptional ? " = nil" : "")" }
            .joined(separator: ", ")
    }
    
    private static func generateDefaultInitAssignments(for properties: [PropertyInfo]) -> String {
        properties
            .map { "self.\($0.name) = \($0.name)" }
            .joined(separator: "\n    ")
    }
    
    private static func hasDefaultInitializer(in structDecl: StructDeclSyntax) -> Bool {
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
    
    private static func extractAccessLevel(from declaration: StructDeclSyntax) -> String {
        for modifier in declaration.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public):
                return "public "
            case .keyword(.internal):
                return ""
            case .keyword(.private):
                return "private "
            case .keyword(.fileprivate):
                return "fileprivate "
            default:
                continue
            }
        }
        return ""
    }
}
