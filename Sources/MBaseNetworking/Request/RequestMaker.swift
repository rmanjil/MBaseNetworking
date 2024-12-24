//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

@available(macOS 10.15.0, *)
@available(iOS 13.0.0, *)
public struct RequestMaker {
    typealias NetworkResult<O> = (Result<NetworkingResponse<O>, NetworkingError>)
    private let router: NetworkingRouter
    private let config: NetworkingConfiguration
    
    init(router: NetworkingRouter, config: NetworkingConfiguration) {
        self.router = router
        self.config = config
    }
    
   
    func makeDataRequest<O>() async -> NetworkResult<O> {
        return await performRequest()
    }
    
    func makeMultiRequest<O>(multipart: [File]) async -> NetworkResult<O> {
        return await performRequest(multipart: multipart)
    }
    
    private func performRequest<O>(multipart: [File] = []) async -> NetworkResult<O> {
        do {
            let requestBuilder = RequestBuilder(router: router, config: config)
            let request: URLRequest
            var parameter: Parameters = [:]
            if  multipart.isEmpty { request = try requestBuilder.getRequest() } else {
                let multi =  try requestBuilder.getMultipartRequest()
                request = multi.request
                parameter = multi.parameters
            }
            let session  = URLSession(configuration: config.sessionConfiguration)
            return await tokenValidation(session, request: request, parameters: parameter, multipart: multipart)
        } catch {
            return .failure(NetworkingError(error))
        }
    }
    
    private func tokenValidation<O>(_ session: URLSession, request: URLRequest, parameters: Parameters = [:], multipart: [File] = []) async -> NetworkResult<O> {
        if  router.needsAuthorization,  await !updateTokenIfNeeded()  {
            return .failure(NetworkingError("TOKEN_EXPIRE"))
        }
        return await checkMultipartThenRequest(session, request: request, parameters: parameters, multipart: multipart)
    }
    
    private func updateTokenIfNeeded() async -> Bool  {
        guard config.tokenManageable.isTokenValid() else {
            return await refreshToken()
        }
        return true
    }
    
    private func refreshToken() async -> Bool {
        await config.tokenManageable.refreshToken()
    }
    
    private func checkMultipartThenRequest<O>(_ session: URLSession, request: URLRequest, parameters: Parameters, multipart: [File]) async -> NetworkResult<O> {
        if multipart.isEmpty {
            return  await normalRequest(session, request: request)
        }
        return await multipartRequest(session, request: request, parameters: parameters, multipart: multipart)
    }
    
    private func normalRequest<O>(_ session: URLSession, request: URLRequest) async -> RequestMaker.NetworkResult<O> {
        var statusCode: Int?
        do {
            
            let (data, response)  = try await session.data(for: request)
            if let httpURLResponse = response as? HTTPURLResponse {
                statusCode = httpURLResponse.statusCode
                config.headerHandler.extract(header: httpURLResponse.allHeaderFields)
            }
            if config.printLogger {
                Logger.log(response, request: request, data: data)
            }
            if  O.self is String.Type, let string = String(data: data, encoding: .utf8), let value = string as? O {
                let   networkResponse = NetworkingResponse<O>(router: router, data: data, request: request, response: response, object: value)
                return  await handleResponse(networkResponse: networkResponse, session: session, request: request)
            }
            if let decodableType = O.self as? Decodable.Type {
                let object =  try JSONDecoder().decode(decodableType, from: data)
                let  networkResponse = NetworkingResponse<O>(router: router, data: data, request: request, response: response, object: object as? O)
                return  await handleResponse(networkResponse: networkResponse, session: session, request: request)
            }
            return .failure(NetworkingError("Response is not in correct format."))
            
        } catch let error as DecodingError {
            switch error {
                
            case .typeMismatch(let type, let context) :
                let keyPath = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
                let message = "Type '\(type)' '{{\(keyPath)}}' mismatch: \(context.debugDescription)"
                return .failure(NetworkingError(message, code: statusCode ?? error.errorCode))
            case .valueNotFound(let value,let context):
                    let keyPath = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
                let message = "value '\(value)'  '{{\(keyPath)}}' mismatch: \(context.debugDescription)"
                return .failure(NetworkingError(message))
            case .keyNotFound(let key, let context):
                    let keyPath = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
                let message = "Key '\(key)'  '{{\(keyPath)}}' mismatch: \(context.debugDescription)"
                return .failure(NetworkingError(message))
            case .dataCorrupted(let context):
                    let keyPath = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
                let message = "Data  corrupted  '{{\(keyPath)}}' : \(context.debugDescription)"
                return .failure(NetworkingError(message, code: statusCode ?? error.errorCode))
            @unknown default:
                return .failure(NetworkingError(error.localizedDescription, code: statusCode ?? error.errorCode))
            }
        }
       /* catch let DecodingError.typeMismatch(type, context) {
            let message = "Type '\(type)' mismatch: \(context.debugDescription)"
            return .failure(NetworkingError(message, code: statusCode))
        } catch  let DecodingError.keyNotFound(key, context) {
            let message = "Key '\(key)' mismatch: \(context.debugDescription)"
            return .failure(NetworkingError(message))
        } catch let DecodingError.valueNotFound(value, context) {
            let message = "value '\(value)' mismatch: \(context.debugDescription)"
            return .failure(NetworkingError(message))
        }*/ catch {
            return .failure(NetworkingError(error.localizedDescription, code: statusCode ?? error.errorCode))
        }
    }
    
    
    private func handleResponse<O>(networkResponse: NetworkingResponse<O>, session: URLSession, request: URLRequest) async -> RequestMaker.NetworkResult<O> {
        if networkResponse.statusCode == 401 && router.needsAuthorization {
            guard await refreshToken() else {
                return .failure(NetworkingError("TOKEN_EXPIRE"))
            }
            return await normalRequest(session, request: request)
        }
        return .success(networkResponse)
    }
    
    private func multipartRequest<O>(_ session: URLSession, request: URLRequest, parameters: Parameters, multipart: [File]) async -> NetworkResult<O> {
        let boundary = UUID().uuidString
        var request = request
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let bodyData = createBodyWithMultipleImages(parameters: parameters, multipart: multipart, boundary: boundary)
        request.httpBody = bodyData
        
        return await normalRequest(session, request: request)
    }
    
    private func createBodyWithMultipleImages(parameters: Parameters, multipart: [File], boundary: String) -> Data {
        var body = Data()
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        multipart.forEach {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\($0.name)\"; filename=\"\($0.fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \($0.contentType)\r\n\r\n".data(using: .utf8)!)
            body.append($0.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
