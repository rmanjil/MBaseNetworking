//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

/// The struct for building the request with information from router
@available(macOS 10.15.0, *)
struct RequestBuilder {
    /// The router of the request
    let router: NetworkingRouter
    
    /// The session config
    let config: NetworkingConfiguration
    
    func getRequest() throws -> URLRequest {
        let request = try createRequest()
        return try applyEncodings(from: router.encoder, to: request)
    }
    
    func getMultipartRequest() throws -> (request: URLRequest, parameters: Parameters) {
        let request = try createRequest()
        let parameters = combineParameters(from: router.encoder)
        return (request, parameters)
    }
    
    private func createRequest() throws -> URLRequest {
        guard let url = URL(string: router.overridenBaseURL ?? config.baseURL)?.appendingPathComponent(router.path) else {
            throw NetworkingError(.invalidBaseURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = router.httpMethod.identifier
        applyHeaders(config: config, router: router, request: &request)
        return request
    }
    
    private func applyHeaders(config: NetworkingConfiguration, router: NetworkingRouter, request: inout URLRequest) {
        router.headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        config.parameter.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        config.tokenManageable.tokenParam.forEach { request.addValue($1, forHTTPHeaderField: $0)}
        
    }
    
    private func applyEncodings(from encodings: [EncoderType], to request: URLRequest) throws -> URLRequest {
        var updatedRequest = request
        try encodings.forEach { type in
            switch type {
                case .json(let params):
                    try updatedRequest.jsonEncoding(params)
                case .url(let params):
                    try updatedRequest.urlEncoding(params)
            }
        }
        return updatedRequest
    }
    
    private func combineParameters(from encodings: [EncoderType]) -> Parameters {
        var parameters = Parameters()
        encodings.forEach { type in
            switch type {
                case .json(let params), .url(let params):
                    if let params {
                        params.forEach { key, value in parameters[key] = value }
                    }
            }
        }
        return parameters
    }
}
