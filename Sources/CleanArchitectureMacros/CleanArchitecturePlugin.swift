//
//  CleanArchitecturePlugin.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct CleanArchitecturePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MakeRepositoryMacro.self,
        UseCaseMacro.self,
        MakeUseCaseMacro.self,
        ServiceMacro.self
    ]
}
