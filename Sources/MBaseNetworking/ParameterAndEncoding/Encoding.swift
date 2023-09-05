//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//


import Foundation
public enum EncoderType {
    case json(Parameters?)
    case url(Parameters?)
}

// MARK: Sets the parameter as json object to body of the request
extension URLRequest {
    mutating func jsonEncoding(_ parameters: Parameters?) throws {
        guard let params = parameters else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: params, options: .sortedKeys)
            httpBody = data
            setValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            throw NetworkingError(.jsonEncodingFailed(error))
        }
    }
}

// MARK: Sets the params as the url query string if the supported methods are used or add to body otherwise
extension URLRequest {
    
    mutating func urlEncoding(_ parameters: Parameters?) throws {
        guard let params = parameters else { return }
        if let method = httpMethod, supportsURLQuery(method: method), let requestURL = url {
            if var urlComponents = URLComponents(url: requestURL ,resolvingAgainstBaseURL: false) {
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(params)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                url = urlComponents.url
            }
        } else {
            httpBody = params.percentEncoded().data(using: .utf8)
            setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
    }
    
    private func supportsURLQuery(method: String) -> Bool {
        let supportedValues = [HTTPMethod.get, HTTPMethod.delete, HTTPMethod.post].map({$0.identifier})
        return supportedValues.contains(method)
    }
}

extension URLRequest {
    
    private func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    /// Creates a percent-escaped, URL encoded query string components from the given key-value pair recursively.
    ///
    /// - Parameters:
    ///   - key:   Key of the query component.
    ///   - value: Value of the query component.
    ///
    /// - Returns: The percent-escaped, URL encoded query string components.
    private func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        let arrayEncoding = ArrayEncoding.indexInBrackets
        let boolEncoding = BoolEncoding.literal
        switch value {
            case let dictionary as [String: Any]:
                let jsonData = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
                let decoded = String(data: jsonData, encoding: .utf8)!
                components.append((escape(key), escape(decoded)))
            case let array as [Any]:
                for (index, value) in array.enumerated() {
                    components += queryComponents(fromKey: arrayEncoding.encode(key: key, atIndex: index), value: value)
                }
            case let number as NSNumber:
                if number.isBool {
                    components.append((escape(key), escape(boolEncoding.encode(value: number.boolValue))))
                } else {
                    components.append((escape(key), escape("\(number)")))
                }
            case let bool as Bool:
                components.append((escape(key), escape(boolEncoding.encode(value: bool))))
            default:
                components.append((escape(key), escape("\(value)")))
        }
        return components
    }
    
    /// Creates a percent-escaped string following RFC 3986 for a query string key or value.
    ///
    /// - Parameter string: `String` to be percent-escaped.
    ///
    /// - Returns:          The percent-escaped `String`.
    private func escape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .allowedQueryCharacterSet) ?? string
    }
    
    /// Configures how `Array` parameters are encoded.
    private enum ArrayEncoding {
        /// An empty set of square brackets is appended to the key for every value. This is the default behavior.
        case brackets
        /// No brackets are appended. The key is encoded as is.
        case noBrackets
        /// Brackets containing the item index are appended. This matches the jQuery and Node.js behavior.
        case indexInBrackets
        
        func encode(key: String, atIndex index: Int) -> String {
            switch self {
                case .brackets:
                    return "\(key)[]"
                case .noBrackets:
                    return key
                case .indexInBrackets:
                    return "\(key)[\(index)]"
            }
        }
    }
    
    /// Configures how `Bool` parameters are encoded.
    private enum BoolEncoding {
        /// Encode `true` as `1` and `false` as `0`. This is the default behavior.
        case numeric
        /// Encode `true` and `false` as string literals.
        case literal
        
        func encode(value: Bool) -> String {
            switch self {
                case .numeric:
                    return value ? "1" : "0"
                case .literal:
                    return value ? "true" : "false"
            }
        }
    }
}

extension NSNumber {
    fileprivate var isBool: Bool {
        // Use Obj-C type encoding to check whether the underlying type is a `Bool`, as it's guaranteed as part of
        // swift-corelibs-foundation, per [this discussion on the Swift forums](https://forums.swift.org/t/alamofire-on-linux-possible-but-not-release-ready/34553/22).
        String(cString: objCType) == "c"
    }
}
