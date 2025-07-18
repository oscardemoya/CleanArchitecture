//
//  EntityFixItMessage.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum EntityFixItMessage: String, FixItMessage {
    case removeExistingMember
    
    var message: String {
        switch self {
        case .removeExistingMember:
            "Remove existing member"
        }
    }
    
    var fixItID: MessageID {
        MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
