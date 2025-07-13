//
//  ServiceContainerDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum ServiceContainerDiagnostic: String, DiagnosticMessage {
    case notAClass
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notAClass: "'@ServiceContainer' can only be applied to classes."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
