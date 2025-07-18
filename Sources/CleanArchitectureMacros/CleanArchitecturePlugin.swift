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
        InjectableMacro.self,
        ConfigurableMacro.self,
        MakeDataSourceMacro.self,
        MakeRepositoryMacro.self,
        MakeUseCaseMacro.self,
        AppServiceMacro.self,
        ServiceContainerMacro.self,
        ConvertibleMacro.self,
        ModelConvertibleMacro.self,
        EntityMacro.self,
    ]
}
