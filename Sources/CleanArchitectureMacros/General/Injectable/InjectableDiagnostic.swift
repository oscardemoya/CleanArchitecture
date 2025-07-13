//
//  InjectableDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum InjectableDiagnostic: String, DiagnosticMessage {
    case noInitTypes
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .noInitTypes: "Expected at least one protocol to be injectable."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
