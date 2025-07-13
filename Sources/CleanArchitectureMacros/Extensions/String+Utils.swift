//
//  String+Utils.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/12.
//

import Foundation

extension String {
    /// Converts a type name to a variable name (e.g., "RemoteConfig" -> "remoteConfig")
    var asVariableName: String {
        guard let first else { return self }
        return first.lowercased() + dropFirst()
    }
    
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
