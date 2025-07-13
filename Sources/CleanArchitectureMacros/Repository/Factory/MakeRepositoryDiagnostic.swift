//
//  MakeRepositoryDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftDiagnostics

enum MakeRepositoryDiagnostic: String, DiagnosticMessage {
    case noRepositoryProtocol
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .noRepositoryProtocol: "Expected a repository protocol type in the macro."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
