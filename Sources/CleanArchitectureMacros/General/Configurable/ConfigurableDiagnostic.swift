//
//  ConfigurableDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum ConfigurableDiagnostic: String, DiagnosticMessage {
    case noConfigurationType
    case noMultipleConfigurationTypes
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .noConfigurationType: "Expected a type to be used for configuration."
        case .noMultipleConfigurationTypes: "Expected only one type to be used for configuration."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
