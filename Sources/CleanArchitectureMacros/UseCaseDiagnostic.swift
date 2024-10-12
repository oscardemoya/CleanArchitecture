//
//  UseCaseDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftDiagnostics

enum UseCaseDiagnostic: String, DiagnosticMessage {
    case notAStruct
    case noExecuteMethod
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notAStruct:
            return "'@UseCase' can only be applied to structs."
        case .noExecuteMethod:
            return "'@UseCase' must contain at least one function."
        }
    }
    
    var diagnosticID: MessageID {
        return MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
