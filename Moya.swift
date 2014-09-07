//
//  Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation
import Alamofire

/// Block to be executed when a request has completed.
public typealias MoyaCompletion = (data: NSData?, error: NSError?) -> ()

/// General-purpose class to store some enums and class funcs.
public class Moya {
    
    /// Represents an HTTP method.
    public enum Method {
        case GET, POST, PUT, DELETE
        
        func method() -> Alamofire.Method {
            switch self {
            case .GET:
                return .GET
            case .POST:
                return .POST
            case .PUT:
                return .PUT
            case .DELETE:
                return .DELETE
            }
        }
    }
    
    /// Choice of parameter encoding.
    public enum ParameterEncoding {
        case URL
        case JSON
        case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
        case Custom((NSURLRequest, [String: AnyObject]?) -> (NSURLRequest, NSError?))
        
        func parameterEncoding() -> Alamofire.ParameterEncoding {
            switch self {
            case .URL:
                return .URL
            case .JSON:
                return .JSON
            case .PropertyList(let format, let options):
                return .PropertyList(format, options)
            case .Custom(let closure):
                return .Custom(closure)
            }
        }
    }
    
    /// Default HTTP method is GET.
    public class func DefaultMethod() -> Method {
        return Method.GET
    }
    
    /// Default parameters are empty.
    public class func DefaultParameters() -> [String: AnyObject] {
        return Dictionary<String, AnyObject>()
    }
}

/// Protocol defining the relative path of an enum.
public protocol MoyaPath {
    var path : String { get }
}

/// Protocol to define the base URL and sample data for an enum.
public protocol MoyaTarget : MoyaPath {
    var baseURL: NSURL { get }
    var sampleData: NSData { get }
}

/// Request provider class. Requests should be made through this class only.
public class MoyaProvider<T: MoyaTarget> {
    /// Closure that defines the endpoints for the provider.
    public typealias MoyaEndpointsClosure = (T, method: Moya.Method, parameters: [String: AnyObject]) -> (Endpoint<T>)
    /// Closure that resolves an Endpoint into an NSURLRequest.
    public typealias MoyaEndpointResolution = (endpoint: Endpoint<T>) -> (NSURLRequest)
    
    let endpointsClosure: MoyaEndpointsClosure
    let endpointResolver: MoyaEndpointResolution
    let stubResponses: Bool
    
    /// Initializes a provider.
    public init(endpointsClosure: MoyaEndpointsClosure, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEnpointResolution(), stubResponses: Bool  = false) {
        self.endpointsClosure = endpointsClosure
        self.endpointResolver = endpointResolver
        self.stubResponses = stubResponses
    }
    
    /// Returns an Endpoint based on the token, method, and parameters by invoking the endpointsClosure.
    public func endpoint(token: T, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<T> {
        return endpointsClosure(token, method: method, parameters: parameters)
    }
    
    /// Designated request-making method.
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject], completion: MoyaCompletion) {
        let endpoint = self.endpoint(token, method: method, parameters: parameters)
        let request = endpointResolver(endpoint: endpoint)
        
        if (stubResponses) {
            // Need to dispatch to the next runloop to give the subject a chance to be subscribed to (useful for unit tests)
            dispatch_async(dispatch_get_main_queue(), {
                switch endpoint.sampleResponse {
                case .Success(let data):
                    completion(data: data, error: nil)
                case .Error(let error):
                    completion(data: nil, error: error)
                }
            })
        } else {
            Alamofire.Manager.sharedInstance.request(request)
                .response({(request: NSURLRequest, reponse: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                    // Alamofire always sense the data param as an NSData? type, but we'll
                    // add a check just in case something changes in the future.
                    if let data = data as? NSData {
                        completion(data: data, error: error)
                    } else {
                        completion(data: nil, error: error)
                    }
                })
        }
    }
    
    public func request(token: T, parameters: [String: AnyObject], completion: MoyaCompletion) {
        request(token, method: Moya.DefaultMethod(), parameters: parameters, completion)
    }

    public func request(token: T, method: Moya.Method, completion: MoyaCompletion) {
        request(token, method: method, parameters: Moya.DefaultParameters(), completion)
    }
    
    public func request(token: T, completion: MoyaCompletion) {
        request(token, method: Moya.DefaultMethod(), completion)
    }
    
    public class func DefaultEnpointResolution() -> MoyaEndpointResolution {
        return { (endpoint: Endpoint<T>) -> (NSURLRequest) in
            return endpoint.urlRequest
        }
    }
}
