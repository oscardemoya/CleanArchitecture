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
        let isEquatableKey: Bool
        var isOptional: Bool { type.hasSuffix("?") || type.hasPrefix("Optional<") }
        var isArray: Bool { type.isArrayType }
        
        var initDefaultValue: String {
            if isOptional {
                " = nil"
            } else if isArray {
                " = []"
            } else if type == "String" {
                " = \"\""
            } else if type == "Int" || type == "Double" || type == "Float" {
                " = 0"
            } else if type == "Bool" {
                " = false"
            } else if type == "UUID" {
                " = UUID()"
            } else if type == "Date" {
                " = .now"
            } else {
                ""
            }
        }
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
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
        let conformsToEquatable = checkEquatableConformance(in: structDecl)
        
        var members: [DeclSyntax] = []
        
        // Generate default init if needed
        if !hasDefaultInit {
            let defaultInit = DeclSyntax(
                """
                \(raw: accessLevel)init(
                \(raw: generateDefaultInitParametersWithTypes(for: properties))
                ) {
                    \(raw: generateDefaultInitAssignments(for: properties))
                }
                """
            )
            members.append(defaultInit)
        }
        
        // Generate Equatable implementation if struct conforms to Equatable
        if conformsToEquatable {
            let equatableProperties = properties.filter { $0.isEquatableKey }
            
            if !equatableProperties.isEmpty {
                let equalityOperator = DeclSyntax(
                    """
                    \(raw: accessLevel)static func == (lhs: Self, rhs: Self) -> Bool {
                        \(raw: generateEqualityChecks(for: equatableProperties))
                    }
                    """
                )
                members.append(equalityOperator)
            }
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
            
            guard variableDecl.modifiers.allSatisfy({ $0.name.tokenKind != .keyword(.static) }) else {
                continue
            }
            
            guard variableDecl.bindings.allSatisfy({ $0.accessorBlock == nil }) else {
                continue
            }
            
            // Check if property has @EquatableKey attribute
            let hasEquatableKey = variableDecl.attributes.contains { attribute in
                guard let attributeSyntax = attribute.as(AttributeSyntax.self),
                      let attributeName = attributeSyntax.attributeName.as(IdentifierTypeSyntax.self) else {
                    return false
                }
                return attributeName.name.text == "EquatableKey"
            }
            
            for binding in variableDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }
                
                let propertyName = pattern.identifier.text
                let typeDescription = binding.typeAnnotation?
                    .type.description.trimmingCharacters(in: .whitespaces) ?? "Any"
                
                properties.append(PropertyInfo(
                    name: propertyName,
                    type: typeDescription,
                    isEquatableKey: hasEquatableKey
                ))
            }
        }
        
        return properties
    }
    
    private static func checkEquatableConformance(in structDecl: StructDeclSyntax) -> Bool {
        structDecl.inheritanceClause?.inheritedTypes.contains { inherited in
            inherited.type.description.trimmingCharacters(in: .whitespaces) == "Equatable"
        } ?? false
    }
    
    private static func generateDefaultInitParametersWithTypes(for properties: [PropertyInfo]) -> String {
        if properties.isEmpty {
            return ""
        }
        
        let parameters = properties.map { property in
            "    \(property.name): \(property.type)\(property.initDefaultValue)"
        }
        
        return parameters.joined(separator: ",\n")
    }
    
    private static func generateDefaultInitAssignments(for properties: [PropertyInfo]) -> String {
        properties
            .map { "self.\($0.name) = \($0.name)" }
            .joined(separator: "\n    ")
    }
    
    private static func generateEqualityChecks(for properties: [PropertyInfo]) -> String {
        if properties.isEmpty {
            return "true"
        }
        
        // Generate a single return statement with && operators
        let comparisons = properties.map { property in
            "lhs.\(property.name) == rhs.\(property.name)"
        }
        
        return comparisons.joined(separator: " &&\n    ")
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
