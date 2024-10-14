//
//  AppServiceDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum AppServiceDiagnostic: String, DiagnosticMessage {
    case notAClass
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notAClass:
            return "'@UseCase' can only be applied to classes."
        }
    }
    
    var diagnosticID: MessageID {
        return MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
