//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

enum Logger {
    /// Method to log the response of Alamofire request response cycle
    /// - Parameter response: the response received from alamofire request
    static func log(_ response: URLResponse, request: URLRequest, data: Data) {
        //REQUEST OBJECT
        var requestObject = [String: Any]()
        requestObject["HttpMethod"] = request.httpMethod
        requestObject["Headers"] = request.allHTTPHeaderFields
        let httpBody = request.httpBody
        var isValidJSON = true
        do {
            if let httpBody {
                let json = try JSONSerialization.jsonObject(with: httpBody, options: .allowFragments)
                requestObject["RequestData"] = json
            }
        } catch {
            isValidJSON = false
        }
        
        if !isValidJSON {
            if let httpBody {
                if let stringData = String(data: httpBody, encoding: .utf8) {
                    requestObject["RequestData"] = stringData
                }
            }
        }
        
        if let apiLink  = request.url?.absoluteString {
            requestObject["APILink"] = apiLink
            print("APILink: \(apiLink)")
        }
        
        var log = [String: Any]()
        log["HTTP_REQUEST_OBJECT"] = requestObject
        
        //RESPONSE OBJECT
        var responseObject = [String: Any]()
        if let urlResponse = response as? HTTPURLResponse {
            responseObject["StatusCode"] = urlResponse.statusCode
        }
        
        log["HTTP_RESPONSE_OBJECT"] = responseObject
        
        //DATA OBJECT
        var requiredRawInfo = false
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            log["DATA"]  = json
            
        } catch {
            print("CANT COVERT TO JSON \(error.localizedDescription)")
            requiredRawInfo = true
        }
        if let  stringyfied = String(data: data, encoding: .utf8), requiredRawInfo {
            log["RAW_DATA"] = stringyfied
        }
        
        //convert to data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: log, options: .prettyPrinted)
            print(String(data: jsonData, encoding: .utf8) ?? "EMPTY_RESPONSE")
        } catch {
            print("Unable to convert log to data")
        }
    }
}
