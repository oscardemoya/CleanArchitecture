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
        var domainType: String { (type.arrayElementType ?? type).replacingOccurrences(of: "Data", with: "") }
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
        
        var asDomainEntity: String {
            if let arrayType = type.arrayElementType, arrayType.hasSuffix("Data") {
                "\(name).map(\\.asDomainEntity)"
            } else if type.hasSuffix("Data") {
                "\(name).asDomainEntity"
            } else {
                name
            }
        }
        
        var asDataModel: String {
            if let arrayType = type.arrayElementType, arrayType.hasSuffix("Data") {
                "entity.\(name).map { \(arrayType)(entity: $0) }"
            } else if type.hasSuffix("Data") {
                "\(type)(entity: entity.\(name))"
            } else {
                "entity.\(domainKey)"
            }
        }
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate struct declaration
        guard let structDecl = ValidationHelper.validateStructDeclaration(node, declaration, context) else {
            return []
        }
        
        // Validate struct naming
        let structName = structDecl.name.text
        guard ValidationHelper.validateStructNaming(node, structDecl, structName, context) else {
            return []
        }
        
        // Check for existing members
        if StructInspector.hasExistingConversionMembers(in: structDecl) {
            ValidationHelper.reportExistingMembersError(node, context)
            return []
        }
        
        // Extract necessary information
        let domainModelName = String(structName.dropLast(4))
        let properties = PropertyExtractor.extractPropertiesWithTypes(from: structDecl)
        
        // Validate properties
        if properties.isEmpty {
            ValidationHelper.reportMissingPropertiesError(structDecl, context)
            return []
        }
        
        // Generate members
        return CodeGenerator.generateMembers(
            structDecl: structDecl,
            domainModelName: domainModelName,
            properties: properties
        )
    }
}
