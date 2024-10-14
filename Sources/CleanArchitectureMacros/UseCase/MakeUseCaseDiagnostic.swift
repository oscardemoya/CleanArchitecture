//
//  MakeUseCaseDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftDiagnostics

enum MakeUseCaseDiagnostic: String, DiagnosticMessage {
    case noRepositoryProtocol
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .noRepositoryProtocol:
            return "Expected a repository protocol type in the macro."
        }
    }
    
    var diagnosticID: MessageID {
        return MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
