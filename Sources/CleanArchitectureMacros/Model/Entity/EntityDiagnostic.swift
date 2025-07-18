//
//  EntityDiagnostic.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum EntityDiagnostic: String, DiagnosticMessage {
    case notAStruct
    case missingProperties
    case existingMember
    
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notAStruct:
            "'@Entity' can only be applied to structs."
        case .missingProperties:
            "No properties found to map in the struct."
        case .existingMember:
            "Member already exists. Remove existing implementation before applying macro."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
