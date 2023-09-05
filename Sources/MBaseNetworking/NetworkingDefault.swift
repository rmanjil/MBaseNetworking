//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

@available(macOS 10.15.0, *)
@available(iOS 13.0.0, *)
public class NetworkingDefault: NetworkConformable {
    public func dataRequest<T>(router: NetworkingRouter, type: T.Type) async throws -> T? {
        nil
    }
    
    
    /// make the instance shared
    public static let `default` = NetworkingDefault()
    private init() {}
    
    /// The networking configuration
    private var config: NetworkingConfiguration?
    
    /// Method to set the configuration from client side
    /// - Parameter config: The networking configuration
    public static func initialize(with config: NetworkingConfiguration) {
        NetworkingDefault.default.config = config
        _ = Connectivity.default
    }
    
    /// Method to create a response publisher for data
    public func dataRequest<O>(router: NetworkingRouter, type: O.Type)  async throws ->  Response<O> {
        try  await createAndPerformRequest(router, multipart: [])
    }
    
    /// Method to create a response publisher for data
    public func multipartRequest<O>(router: NetworkingRouter, multipart: [File], type: O.Type) async throws -> Response<O> {
        try await createAndPerformRequest(router, multipart: multipart)
    }
    
    private func createAndPerformRequest<O>(_ router: NetworkingRouter, multipart: [File]) async throws ->  Response<O> {
        guard let config = NetworkingDefault.default.config else {
            throw NetworkingError(.networkingNotInitialized)
        }
        
        guard Connectivity.default.status == .connected else {
            throw NetworkingError(.noConnectivity)
        }
        let requestMaker = RequestMaker(router: router, config: config)
        
        let result: RequestMaker.NetworkResult<O> = await (multipart.isEmpty ?   requestMaker.makeDataRequest() :  requestMaker.makeMultiRequest(multipart: multipart))
        
        switch result {
            case .success(let data):
                if let model = data.object {
                    let response = Response(data: model, statusCode: data.statusCode)
                    return response
                }
            case .failure(let error):
                throw error
        }
        
        throw NetworkingError("SOMETHING_WENT_WRONG")
    }
}
