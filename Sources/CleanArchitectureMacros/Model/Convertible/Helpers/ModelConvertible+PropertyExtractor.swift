//
//  ModelConvertible+PropertyExtractor.swift
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
    struct PropertyExtractor {
        static func extractPropertiesWithTypes(from structDecl: StructDeclSyntax) -> [PropertyInfo] {
            var properties: [PropertyInfo] = []
            
            for member in structDecl.memberBlock.members {
                guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                    continue
                }
                
                // Process valid variable declarations only
                if isValidPropertyDeclaration(variableDecl) {
                    let extractedProperties = processBindings(variableDecl)
                    properties.append(contentsOf: extractedProperties)
                }
            }
            
            return properties
        }
        
        private static func isValidPropertyDeclaration(_ variableDecl: VariableDeclSyntax) -> Bool {
            // Check if it's a let/var declaration
            guard variableDecl.bindingSpecifier.tokenKind == .keyword(.let) ||
                    variableDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
                return false
            }
            
            // Ensure it's not a computed property
            guard variableDecl.bindings.allSatisfy({ $0.accessorBlock == nil }) else {
                return false
            }
            
            return true
        }
        
        private static func processBindings(_ variableDecl: VariableDeclSyntax) -> [PropertyInfo] {
            var result: [PropertyInfo] = []
            
            for binding in variableDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }
                
                let propertyName = pattern.identifier.text
                let typeDescription = extractTypeDescription(from: binding)
                let domainKey = extractDomainKey(from: variableDecl, defaultKey: propertyName)
                
                result.append(PropertyInfo(
                    name: propertyName,
                    type: typeDescription,
                    domainKey: domainKey
                ))
            }
            
            return result
        }
        
        private static func extractTypeDescription(from binding: PatternBindingSyntax) -> String {
            binding.typeAnnotation?
                .type.description.trimmingCharacters(in: .whitespaces) ?? "Any"
        }
        
        private static func extractDomainKey(from variableDecl: VariableDeclSyntax, defaultKey: String) -> String {
            for attribute in variableDecl.attributes {
                if let customKey = processConvertibleAttribute(attribute) {
                    return customKey
                }
            }
            return defaultKey
        }
        
        private static func processConvertibleAttribute(_ attribute: AttributeListSyntax.Element) -> String? {
            guard let attributeSyntax = attribute.as(AttributeSyntax.self),
                  let attributeName = attributeSyntax.attributeName.as(IdentifierTypeSyntax.self),
                  attributeName.name.text == "Convertible" else {
                return nil
            }
            
            guard let arguments = attributeSyntax.arguments?.as(LabeledExprListSyntax.self) else {
                return nil
            }
            
            for argument in arguments {
                if argument.label?.text == "key",
                   let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let key = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    return key.content.text
                }
            }
            
            return nil
        }
    }
}
