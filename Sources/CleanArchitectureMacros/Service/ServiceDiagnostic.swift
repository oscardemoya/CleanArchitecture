//
//  ServiceDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum ServiceDiagnostic: String, DiagnosticMessage {
    case notAClass
    case noExecuteMethod
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notAClass:
            return "'@UseCase' can only be applied to classes."
        case .noExecuteMethod:
            return "'@UseCase' must contain at least one function."
        }
    }
    
    var diagnosticID: MessageID {
        return MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
