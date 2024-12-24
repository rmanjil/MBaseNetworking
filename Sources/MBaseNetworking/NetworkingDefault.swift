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
    
    private func createAndPerformRequest<O>(_ router: NetworkingRouter, multipart: [File], isForceMultiPart: Bool) async  -> NetworkResult<O> {
        guard let config = NetworkingDefault.default.config else {
            return .failure(NetworkingError(.networkingNotInitialized))
        }
        
        guard Connectivity.default.status == .connected else {
            return .failure( NetworkingError(.noConnectivity))
        }
        let requestMaker = RequestMaker(router: router, config: config, isForceMultiPart: isForceMultiPart)
        
        let result: RequestMaker.NetworkResult<O> = await (multipart.isEmpty ?   requestMaker.makeDataRequest() :  requestMaker.makeMultiRequest(multipart: multipart))
        
        switch result {
            case .success(let data):
                if let model = data.object {
                    let response = Response(data: model, statusCode: data.statusCode)
                    return .success(response)
                }
            case .failure(let error):
                return  .failure(error)
        }
        
        return  .failure(NetworkingError("SOMETHING_WENT_WRONG"))
    }
    
    
    public func dataRequest<T>(router: any NetworkingRouter, type: T.Type) async -> Result<T, NetworkingError> {
        .failure(.init("No DATA", code: 0))
    }
    
    public func dataRequest<O>(router: any NetworkingRouter, type: O.Type) async  -> NetworkResult<O> where O : Decodable {
        await createAndPerformRequest(router, multipart: [], isForceMultiPart: false)
    }
    
    public func multipartRequest<O>(router: any NetworkingRouter, multipart: [File], type: O.Type, isForceMultiPart: Bool = false) async  -> NetworkResult<O> where O : Decodable {
        await createAndPerformRequest(router, multipart: multipart, isForceMultiPart: isForceMultiPart)
    }
}
