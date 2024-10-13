//
//  RepositoryFactoryDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftDiagnostics

enum RepositoryFactoryDiagnostic: String, DiagnosticMessage {
    case noRepositoryProtocol
    case noConcreteRepository
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .noRepositoryProtocol:
            return "Expected a repository protocol type in the macro."
        case .noConcreteRepository:
            return "Expected a concrete repository implementation."
        }
    }
    
    var diagnosticID: MessageID {
        return MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
