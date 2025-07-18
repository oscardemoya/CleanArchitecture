//
//  ConvertibleMacro.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/16.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct ConvertibleMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro just marks properties, actual work is done by ModelConvertibleMacro
        []
    }
}
