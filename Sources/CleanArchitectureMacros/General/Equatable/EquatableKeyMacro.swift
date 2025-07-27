//
//  EquatableKeyMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/23.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct EquatableKeyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro is just a marker, no code generation needed
        []
    }
}
