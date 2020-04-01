//
//  HTTPError.swift
//  IoT Platform
//
//  Created by Tom Shen on 2020/4/1.
//  Copyright © 2020 Tom Shen. All rights reserved.
//

import Foundation

/// Combine helper enum for HTTP downloading
enum HTTPError: LocalizedError {
    case invalidResponse
    case permissionDenied
    case invalidData
    case statusCode(code: Int)
    case custom(error: String) // Use for error relating to download but not listed here
    
    func getErrorString() -> String {
        switch self {
        case .permissionDenied:
            return "Permission Denied! Please restart the app."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .statusCode(let code):
            return "The server returned an invalid status code (\(code))."
        case .invalidData:
            return "The server returned unreadable data."
        case .custom(let errStr):
            return errStr
        }
    }
    
    /// Standard check for server errors (throws if error, returns if success)
    static func assertHTTPStatus(_ response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        
        guard response.statusCode != 401 && response.statusCode != 403 else {
            // Permission denied from server
            throw HTTPError.permissionDenied
        }
        
        guard response.statusCode == 200 else {
            throw HTTPError.statusCode(code: response.statusCode)
        }
    }
}
