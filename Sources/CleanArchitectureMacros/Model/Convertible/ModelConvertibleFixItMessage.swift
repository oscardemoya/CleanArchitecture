//
//  ModelConvertibleFixItMessage.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum ModelConvertibleFixItMessage: String, FixItMessage {
    case addDataSuffix
    case removeExistingMember
    
    var message: String {
        switch self {
        case .addDataSuffix:
            "Add 'Data' suffix to struct name"
        case .removeExistingMember:
            "Remove existing member"
        }
    }
    
    var fixItID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
