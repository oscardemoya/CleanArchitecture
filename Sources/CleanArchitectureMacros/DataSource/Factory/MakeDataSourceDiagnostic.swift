//
//  MakeDataSourceDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftDiagnostics

enum MakeDataSourceDiagnostic: String, DiagnosticMessage {
    case invalidArguments
    case missingAnyKeyword
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .invalidArguments: "Expected a datasource protocol and configuration types in the macro."
        case .missingAnyKeyword: "Use of protocol as a type must be annotated with the 'any' keyword."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
