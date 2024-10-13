//
//  UseCaseMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct UseCaseMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext)
    throws -> [DeclSyntax] {
        
        // Ensure the macro is applied to a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            
            // Check if the macro is applied to a class
            if let classDecl = declaration.as(ClassDeclSyntax.self) {
                
                // Add a FixIt to suggest replacing `class` with `struct`
                let fixIt = FixIt(
                    message: UseCaseFixItMessage.replaceClassWithStruct,
                    changes: [
                        FixIt.Change.replace(
                            oldNode: Syntax(classDecl.classKeyword),
                            newNode: Syntax(TokenSyntax.keyword(.struct))
                        )
                    ]
                )
                
                // Attach the diagnostic with the FixIt to the context
                let diagnostic = Diagnostic(
                    node: node,
                    message: UseCaseDiagnostic.notAStruct,
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

        let typeName = structDecl.name.text
        
        // Extract property declarations from the struct
        let properties = structDecl.memberBlock.members.compactMap { member -> (name: String, type: String)? in
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
        
        // Extract function signatures from the struct
        let functionSignatures = structDecl.memberBlock.members.compactMap { member -> String? in
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                return nil
            }
            
            // Get function name and parameters
            let funcName = funcDecl.name.text
            let parameters = funcDecl.signature.parameterClause.parameters
            let funcParams = parameters.map { "\($0.firstName.text): \($0.type)" }.joined(separator: ", ")
            
            // Check if the function is async and/or throws
            let asyncSpecifier = funcDecl.signature.effectSpecifiers?.asyncSpecifier?.text ?? ""
            let asyncKeyword = asyncSpecifier.isEmpty ? "" : " async"
            let throwsSpecifier = funcDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.text ?? ""
            let throwsKeyword = throwsSpecifier.isEmpty ? "" : " throws"
            let returnClause = funcDecl.signature.returnClause
            let returnType = returnClause?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let returnExpression = returnType.isEmpty ? "" : " -> \(returnType)"
            
            return "func \(funcName)(\(funcParams))\(asyncKeyword)\(throwsKeyword)\(returnExpression)"
        }
        
        // Ensure the macro have at least one function to execute
        guard !structDecl.memberBlock.members.compactMap({ $0.decl.as(FunctionDeclSyntax.self) }).isEmpty else {
            let diagnostic = Diagnostic(
                node: node,
                message: UseCaseDiagnostic.noExecuteMethod
            )
            context.diagnose(diagnostic)
            return []
        }
        
        // Generate the protocol
        let protocolName = "\(typeName)UseCase"
        let protocolDecl = """
        public protocol \(protocolName) {
            \(functionSignatures.joined(separator: "\n    "))
        }
        """
        
        // Prepare default class properties strings
        let defaultClassProperties = properties.map { "let \($0.name): \($0.type)" }.joined(separator: "\n    ")
        let defaultClassInitProperties = properties.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n        ")
        let defaultClassParams = properties.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
        let initArgs = properties.map { "\($0.name): \($0.name)" }.joined(separator: ", ")
        
        // Prepare function bodies from the struct
        let functionBodies = structDecl.memberBlock.members.compactMap { member -> String? in
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                return nil
            }
            
            // Get function name and parameters
            let funcName = funcDecl.name.text
            let parameters = funcDecl.signature.parameterClause.parameters
            let funcParams = parameters.map { "\($0.firstName.text): \($0.type)" }.joined(separator: ", ")
            let funcArgs = parameters.map { "\($0.firstName.text): \($0.firstName.text)" }.joined(separator: ", ")
            
            // Check if the function is async and/or throws
            let asyncSpecifier = funcDecl.signature.effectSpecifiers?.asyncSpecifier?.text ?? ""
            let asyncKeyword = asyncSpecifier.isEmpty ? "" : " async"
            let awaitKeyword = asyncSpecifier.isEmpty ? "" : "await "
            let throwsSpecifier = funcDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.text ?? ""
            let throwsKeyword = throwsSpecifier.isEmpty ? "" : " throws"
            let tryKeyword = throwsSpecifier.isEmpty ? "" : "try "
            let returnClause = funcDecl.signature.returnClause
            let returnType = returnClause?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let returnExpression = returnType.isEmpty ? "" : " -> \(returnType)"
            
            return """
                func \(funcName)(\(funcParams))\(asyncKeyword)\(throwsKeyword)\(returnExpression) {
                    \(tryKeyword)\(awaitKeyword)useCase.\(funcName)(\(funcArgs))
                }
            """
        }
        
        // Generate default class implementation
        let defaultClassName = "\(typeName)DefaultUseCase"
        let defaultClassDecl = """
        class \(defaultClassName): \(protocolName) {
            \(defaultClassProperties)
            let useCase: \(typeName)
        
            init(\(defaultClassParams)) {
                \(defaultClassInitProperties)
                self.useCase = \(typeName)(\(initArgs))
            }
        
        \(functionBodies.joined(separator: "\n\n"))
        }
        """
        
        // Generate the factory class and method
        let factoryName = "\(typeName)Factory"
        let factoryDecl = """
        public struct \(factoryName) {
            public static func makeUseCase(\(defaultClassParams)) -> \(protocolName) {
                \(defaultClassName)(\(initArgs))
            }
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let protocolSyntax = DeclSyntax(stringLiteral: protocolDecl)
        let defaultClassSyntax = DeclSyntax(stringLiteral: defaultClassDecl)
        let factoryStructSyntax = DeclSyntax(stringLiteral: factoryDecl)
        
        return [protocolSyntax, defaultClassSyntax, factoryStructSyntax]
    }
}
