//
//  MacroDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum MacroDiagnostic: String, DiagnosticMessage {
    case notAClass
    case notAStruct
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notAClass: "This macro can only be applied to classes."
        case .notAStruct: "This macro can only be applied to structs."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
