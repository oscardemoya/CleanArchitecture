//
//  MacroFixItMessage.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum MacroFixItMessage: String, FixItMessage {
    case replaceStructWithClass
    case replaceClassWithStruct
    
    var message: String {
        switch self {
        case .replaceStructWithClass: "Replace 'struct' with 'class'"
        case .replaceClassWithStruct: "Replace 'class' with 'struct'"
        }
    }
    
    var fixItID: MessageID {
        return MessageID(domain: "CleanArchitectureMacros", id: rawValue)
    }
}
