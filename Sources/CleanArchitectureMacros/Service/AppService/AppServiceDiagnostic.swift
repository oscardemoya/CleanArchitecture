//
//  AppServiceDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum AppServiceDiagnostic: String, DiagnosticMessage {
    case notAClass
    case noUseCaseFactoryType
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notAClass: "'@AppService' can only be applied to classes."
        case .noUseCaseFactoryType: "Expected a use case factory type in the macro."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
