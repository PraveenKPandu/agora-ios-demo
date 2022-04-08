//
//  REST.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 06/04/2022.
//

import Foundation

enum APIMethod: String {
    case get = "GET"
    case post = "POST"
}

protocol REST {
    var baseURL: String { get }
    var path: String { get }
    var parameters: [String: Any]? { get }
    var method: APIMethod { get }
}

extension REST {
    public var urlRequest: URLRequest {
        guard let url = self.url else {
            fatalError("URL could not be built")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        return request
    }

    private var url: URL? {
        var urlComponents = URLComponents(string: baseURL)
        urlComponents?.path = path

        if method == .get {
            // add query items to url
            guard let parameters = parameters as? [String: String] else {
                fatalError("parameters for GET http method must conform to [String: String]")
            }
            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        } else if method == .post {
            // To be extended
        }

        return urlComponents?.url
    }
}
