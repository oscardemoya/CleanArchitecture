//
//  ModelConvertibleCode.swift
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
    struct CodeGenerator {
        static func generateMembers(
            structDecl: StructDeclSyntax,
            domainModelName: String,
            properties: [PropertyInfo]
        ) -> [DeclSyntax] {
            let accessLevel = extractAccessLevel(from: structDecl)
            let hasDefaultInit = StructInspector.hasDefaultInitializer(in: structDecl)
            
            var members: [DeclSyntax] = []
            
            // Generate computed property
            members.append(generateAsDomainEntityProperty(
                accessLevel: accessLevel,
                domainModelName: domainModelName,
                properties: properties
            ))
            
            // Generate default init if needed
            if !hasDefaultInit {
                members.append(generateDefaultInitializer(
                    accessLevel: accessLevel,
                    properties: properties
                ))
            }
            
            // Generate entity init
            members.append(generateEntityInitializer(
                accessLevel: accessLevel,
                domainModelName: domainModelName,
                properties: properties
            ))
            
            return members
        }
        
        private static func generateAsDomainEntityProperty(
            accessLevel: String,
            domainModelName: String,
            properties: [PropertyInfo]
        ) -> DeclSyntax {
            DeclSyntax(
            """
            \(raw: accessLevel)var asDomainEntity: \(raw: domainModelName) {
                .init(
            \(raw: generateDomainInitializerArguments(for: properties))
                )
            }
            """
            )
        }
        
        private static func generateDefaultInitializer(
            accessLevel: String,
            properties: [PropertyInfo]
        ) -> DeclSyntax {
            DeclSyntax(
            """
            \(raw: accessLevel)init(\(raw: generateDefaultInitParametersWithTypes(for: properties))) {
                \(raw: generateDefaultInitAssignments(for: properties))
            }
            """
            )
        }
        
        private static func generateEntityInitializer(
            accessLevel: String,
            domainModelName: String,
            properties: [PropertyInfo]
        ) -> DeclSyntax {
            DeclSyntax(
            """
            \(raw: accessLevel)init(entity: \(raw: domainModelName)) {
                self.init(
            \(raw: generateDTOInitializerArguments(for: properties))
                )
            }
            """
            )
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
}
