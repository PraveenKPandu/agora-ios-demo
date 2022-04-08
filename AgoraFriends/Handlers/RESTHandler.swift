//
//  RESTHandler.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 06/04/2022.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)
    case empty
}

class RESTHandler<T: REST> {
    var urlSession = URLSession.shared

    init() { }

    func load(REST: T, completion: @escaping (Result<Data>) -> Void) {
        call(REST.urlRequest, completion: completion)
    }

    func load<U>(REST: T, decodeType: U.Type, completion: @escaping (Result<U>) -> Void) where U: Decodable {
        call(REST.urlRequest) { result in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                do {
                    let resp = try decoder.decode(decodeType, from: data)
                    completion(.success(resp))
                }
                catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            case .empty:
                completion(.empty)
            }
        }
    }
}

extension RESTHandler {
    private func call(_ request: URLRequest, deliverQueue: DispatchQueue = DispatchQueue.main, completion: @escaping (Result<Data>) -> Void) {
        urlSession.dataTask(with: request) { (data, _, error) in
            if let error = error {
                deliverQueue.async {
                    completion(.failure(error))
                }
            } else if let data = data {
                deliverQueue.async {
                    completion(.success(data))
                }
            } else {
                deliverQueue.async {
                    completion(.empty)
                }
            }
            }.resume()
    }
}
