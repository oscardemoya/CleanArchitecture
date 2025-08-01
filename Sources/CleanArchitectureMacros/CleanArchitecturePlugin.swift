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
        ServiceContainerMacro.self,
        AppServiceMacro.self,
        MakeUseCaseMacro.self,
        MakeRepositoryMacro.self,
        MakeDataSourceMacro.self,
        InjectableMacro.self,
        ConfigurableMacro.self,
        ConvertibleMacro.self,
        ModelConvertibleMacro.self,
        EntityMacro.self,
        EquatableKeyMacro.self
    ]
}
