//
//  ModelConvertibleMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/16.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct ModelConvertibleMacro: MemberMacro {
    struct PropertyInfo {
        let name: String
        let type: String
        let domainKey: String
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: ModelConvertibleDiagnostic.notAStruct
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let structName = structDecl.name.text
        
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
            return []
        }
        
        if hasExistingConversionMembers(in: structDecl) {
            let diagnostic = Diagnostic(
                node: node,
                message: ModelConvertibleDiagnostic.existingMember
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let domainModelName = String(structName.dropLast(4))
        let properties = extractPropertiesWithTypes(from: structDecl)
        
        if properties.isEmpty {
            let diagnostic = Diagnostic(
                node: structDecl,
                message: ModelConvertibleDiagnostic.missingProperties
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let accessLevel = extractAccessLevel(from: structDecl)
        let hasDefaultInit = hasDefaultInitializer(in: structDecl)
        
        var members: [DeclSyntax] = []
        
        // Generate computed property
        let asDomainEntityProperty = DeclSyntax(
            """
            \(raw: accessLevel)var asDomainEntity: \(raw: domainModelName) {
                .init(
            \(raw: generateDomainInitializerArguments(for: properties))
                )
            }
            """
        )
        members.append(asDomainEntityProperty)
        
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
        
        // Generate entity init
        let entityInitializer = DeclSyntax(
            """
            \(raw: accessLevel)init(entity: \(raw: domainModelName)) {
                self.init(
            \(raw: generateDTOInitializerArguments(for: properties))
                )
            }
            """
        )
        members.append(entityInitializer)
        
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
                var domainKey = propertyName
                
                // Get the type
                let typeDescription = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespaces) ?? "Any"
                
                // Check for @Convertible attribute
                for attribute in variableDecl.attributes {
                    guard let attributeSyntax = attribute.as(AttributeSyntax.self),
                          let attributeName = attributeSyntax.attributeName.as(IdentifierTypeSyntax.self),
                          attributeName.name.text == "Convertible" else {
                        continue
                    }
                    
                    if let arguments = attributeSyntax.arguments?.as(LabeledExprListSyntax.self) {
                        for argument in arguments {
                            if argument.label?.text == "key",
                               let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                               let key = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                                domainKey = key.content.text
                            }
                        }
                    }
                }
                
                properties.append(PropertyInfo(
                    name: propertyName,
                    type: typeDescription,
                    domainKey: domainKey
                ))
            }
        }
        
        return properties
    }
    
    private static func generateDefaultInitParametersWithTypes(for properties: [PropertyInfo]) -> String {
        properties
            .map { "\($0.name): \($0.type)" }
            .joined(separator: ", ")
    }
    
    private static func generateDefaultInitAssignments(for properties: [PropertyInfo]) -> String {
        properties
            .map { "self.\($0.name) = \($0.name)" }
            .joined(separator: "\n    ")
    }
    
    private static func generateDomainInitializerArguments(for properties: [PropertyInfo]) -> String {
        properties
            .map { "        \($0.domainKey): \($0.name)" }
            .joined(separator: ",\n")
    }
    
    private static func generateDTOInitializerArguments(for properties: [PropertyInfo]) -> String {
        properties
            .map { "        \($0.name): entity.\($0.domainKey)" }
            .joined(separator: ",\n")
    }
    
    private static func hasExistingConversionMembers(in structDecl: StructDeclSyntax) -> Bool {
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
