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
            let params = funcDecl.signature.parameterClause.parameters.map { param -> String in
                let paramName = param.firstName.text
                let paramType = param.type.description
                return "\(paramName): \(paramType)"
            }.joined(separator: ", ")
            
            // Check if the function is async and/or throws
            let asyncKeyword = funcDecl.signature.effectSpecifiers?.asyncSpecifier?.text ?? ""
            let throwsKeyword = funcDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.text ?? ""
            let returnType = funcDecl.signature.returnClause?.type.description ?? "Void"
            
            return "func \(funcName)(\(params)) \(asyncKeyword) \(throwsKeyword) -> \(returnType)"
        }
        
        // Extract the first method from the struct to use in protocol and class generation
        guard let firstMethod = structDecl.memberBlock.members.compactMap({ $0.decl.as(FunctionDeclSyntax.self) }).first else {
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
        
        // Prepare execute method signature
        let methodName = firstMethod.name.text
        let methodSignature = firstMethod.signature.description
        
        // Prepare execute method argument string
        let methodArgs = firstMethod.signature.parameterClause.parameters
            .map { "\($0.firstName.text): \($0.firstName.text)" }
            .joined(separator: ", ")
        
        // Generate default class implementation
        let defaultClassName = "\(typeName)DefaultUseCase"
        let defaultClassDecl = """
        class \(defaultClassName): \(protocolName) {
            let authRepository: AuthRepository
            let profileRepository: ProfileRepository
            let useCase: \(typeName)
        
            init(authRepository: AuthRepository, profileRepository: ProfileRepository) {
                self.authRepository = authRepository
                self.profileRepository = profileRepository
                self.useCase = \(typeName)(authRepository: authRepository, profileRepository: profileRepository)
            }
        
            func \(methodName)\(methodSignature) {
                return try await useCase.\(methodName)(\(methodArgs))
            }
        }
        """
        
        // Prepare factory method parameter string
        let factoryMethodParams = properties
            .map { "\($0.name): \($0.type)" }
            .joined(separator: ", ")

        // Prepare initialization argument string
        let initArgs = properties
            .map { "\($0.name): \($0.name)" }
            .joined(separator: ", ")

        // Generate the factory class and method
        let factoryClassName = "\(typeName)Factory"
        let factoryDecl = """
        public class \(factoryClassName) {
            public static func makeUseCase(\(factoryMethodParams)) -> \(protocolName) {
                return \(defaultClassName)(\(initArgs))
            }
        }
        """
        
        // Parse the generated class, protocol, and method into SwiftSyntax
        let protocolSyntax = DeclSyntax(stringLiteral: protocolDecl)
        let defaultClassSyntax = DeclSyntax(stringLiteral: defaultClassDecl)
        let factoryClassSyntax = DeclSyntax(stringLiteral: factoryDecl)
                
        return [protocolSyntax, defaultClassSyntax, factoryClassSyntax]
    }
}
