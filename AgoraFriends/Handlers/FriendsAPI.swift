//
//  FriendsAPI.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 05/04/2022.
//

import Foundation
import Siesta

let FriendsAPI = _FriendsAPI()

class _FriendsAPI {
    // MARK: - Configuration
    private let service = Service(
        baseURL: "https://agora.praveen.uk/api",
        standardTransformers: [.text])
    
    fileprivate init() {
    #if DEBUG
        SiestaLog.Category.enabled = .detailed
    #endif
        
        let jsonDecoder = JSONDecoder()

        service.configure("/friends") {
            // Refresh search results after 10 seconds (Siesta default is 30)
            $0.expirationTime = 1000
        }
        
        service.configure("**") {
            // This header configuration gets reapplied whenever the user logs in or out.
            $0.headers["Authorization"] = self.basicAuthHeader
        }
        
        service.configureTransformer("/register") {
            // Input type inferred because the from: param takes Data.
            // Output type inferred because jsonDecoder.decode() will return User
            try jsonDecoder.decode(User.self, from: $0.content)
        }
        
    }
    
    // MARK: - Authentication

    func logIn(email: String, password: String) {
        if let auth = "\(email):\(password)".data(using: String.Encoding.utf8) {
            basicAuthHeader = "Basic \(auth.base64EncodedString())"
        }
    }

    func logOut() {
        basicAuthHeader = nil
    }

    var isAuthenticated: Bool {
        return basicAuthHeader != nil
    }
    
    
    private var basicAuthHeader: String? {
        didSet {
            service.invalidateConfiguration()
            service.wipeResources()
        }
    }
    
    func friend(_ username: String) -> Resource {
        return service
            .resource("/friends")
            .child(username.lowercased())
    }
    
}



