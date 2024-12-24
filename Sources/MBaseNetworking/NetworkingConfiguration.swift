//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

@available(iOS 13.0.0, *)
@available(macOS 10.15.0, *)
public struct NetworkingConfiguration {
    
    /// The baseURL for the API
    let baseURL: String
    let parameter: [String: String]
    
    /// The url session connfiguration
    let sessionConfiguration: URLSessionConfiguration
    let tokenManageable: TokenManageable
    let headerHandler: HeaderHandler
    let printLogger: Bool
    
    
    public init(baseURL: String, parameter: [String: String] = [:], tokenManageable: TokenManageable, headerHandler: HeaderHandler, sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default, printLogger: Bool = false) {
        self.baseURL = baseURL
        self.parameter = parameter
        self.sessionConfiguration = sessionConfiguration
        self.tokenManageable = tokenManageable
        self.headerHandler = headerHandler
        self.printLogger = printLogger
    }
    
    /// The configuration information
    public func debugInfo() -> [String: Any] {
        [
            "baseURL": baseURL,
            "sessionConfiguration": sessionConfiguration,
        ]
    }
}
