//
//  GoogleSignInService.swift
//  GoogleSignInDemo
//
//  Created by Nguyen Uy on 11/12/19.
//  Copyright © 2019 Nguyen Uy. All rights reserved.
//

import Foundation
import GTMAppAuth
import AppAuth
import SwiftyJSON
import PromiseKit

class RoundedImageView: NSImageView {
    override func layout() {
        super.layout()
        self.imageScaling = .scaleAxesIndependently
        self.layer?.backgroundColor = .clear
        self.wantsLayer = true
        self.layer?.cornerRadius = self.frame.width / 2
        self.layer?.masksToBounds = true
    }
}

class GoogleSignInProfile {
    let locale: String
    let familyName: String
    let givenName: String
    let picture: String
    let sub: String
    let name: String
    let email: String
    
    init(json: JSON) {
        self.locale = json["locale"].stringValue
        self.familyName = json["family_name"].stringValue
        self.givenName = json["given_name"].stringValue
        self.picture = json["picture"].stringValue
        self.sub = json["sub"].stringValue
        self.name = json["name"].stringValue
        self.email = json["email"].stringValue
    }
}

class GoogleSignInService: NSObject, OIDExternalUserAgent {
    static let kIssuer = "https://accounts.google.com"
    static let kClientID = "REPLACE_BY_YOUR_CLIENT_ID.apps.googleusercontent.com"
    static let kClientSecret = "REPLACE_BY_YOUR_CLIENT_SECRET"
    static let kRedirectURI = "com.googleusercontent.apps.REPLACE_BY_YOUR_CLIENT_ID:/oauthredirect"
    static let kExampleAuthorizerKey = "REPLACE_BY_YOUR_AUTHORIZATION_KEY"
    
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    static let shared = GoogleSignInService()
    
    var auth: GTMAppAuthFetcherAuthorization?
    
    var isAuthed: Bool {
        return auth != nil
    }
    
    private override init() {
        super.init()
        self.loadState()
    }
    
    func loadProfile() -> Promise<GoogleSignInProfile> {
        return Promise { (seal) in
            guard let auth = self.auth else {
                seal.reject(NSError(domain: "GoogleSignIn", code: 0, userInfo: nil))
                return
            }
            
            if let url = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo") {
                let service = GTMSessionFetcherService()
                service.authorizer = auth
                service.fetcher(with: url).beginFetch { (data, error) in
                    guard error == nil else {
                        self.setAuthorization(auth: nil)
                        seal.reject(error!)
                        return
                    }
                    
                    if let data = data {
                        do {
                            let json = try JSON(data: data)
                            seal.fulfill(GoogleSignInProfile(json: json))
                        } catch {
                            seal.reject(error)
                        }
                    } else {
                        seal.reject(NSError(domain: "GoogleSignIn", code: 0, userInfo: nil))
                    }
                }
            }
        }
    }
    
    func signOut() -> Promise<Void> {
        return Promise { (seal) in
            self.setAuthorization(auth: nil)
            seal.fulfill(Void())
        }
    }
    
    func signIn() -> Promise<Void> {
        return Promise { (seal) in
            if self.auth != nil, self.auth!.canAuthorize() {
                seal.fulfill(Void())
            } else {
                OIDAuthorizationService.discoverConfiguration(forIssuer: URL(string: Self.kIssuer)!) { (config, error) in
                    guard error == nil else {
                        seal.reject(error!)
                        return
                    }
                    
                    guard let config = config else {
                        seal.reject(NSError(domain: "GoogleSignIn", code: 0, userInfo: nil))
                        return
                    }
                    
                    let request = OIDAuthorizationRequest(configuration: config,
                                            clientId: Self.kClientID,
                                            clientSecret: Self.kClientSecret,
                                            scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail],
                                            redirectURL: URL(string: Self.kRedirectURI)!,
                                            responseType: OIDResponseTypeCode,
                                            additionalParameters: nil)

                    self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, externalUserAgent: self, callback: { (state, error) in
                        guard error == nil else {
                            seal.reject(error!)
                            return
                        }
                        
                        if state != nil {
                            self.setAuthorization(auth: GTMAppAuthFetcherAuthorization(authState: state!))
                            seal.fulfill(Void())
                        } else {
                            seal.reject(NSError(domain: "GoogleSignIn", code: 0, userInfo: nil))
                        }
                    })
                }
            }
        }
    }
    
    private func setAuthorization(auth: GTMAppAuthFetcherAuthorization?) {
        self.auth = auth
        self.saveState()
    }
    
    private func loadState() {
        if let auth = GTMAppAuthFetcherAuthorization(fromKeychainForName: Self.kExampleAuthorizerKey) {
            self.setAuthorization(auth: auth)
        }
    }
    
    private func saveState() {
        guard let auth = self.auth else {
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Self.kExampleAuthorizerKey)
            return
        }
        
        if auth.canAuthorize() {
            GTMAppAuthFetcherAuthorization.save(auth, toKeychainForName: Self.kExampleAuthorizerKey)
        } else {
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Self.kExampleAuthorizerKey)
        }
    }
    
    func present(_ request: OIDExternalUserAgentRequest, session: OIDExternalUserAgentSession) -> Bool {
        if let url = request.externalUserAgentRequestURL(),
            NSWorkspace.shared.open([url], withAppBundleIdentifier: "com.apple.Safari", options: .default, additionalEventParamDescriptor: nil, launchIdentifiers: nil) {
            return true
        }
        
        return false
    }
    
    func dismiss(animated: Bool, completion: @escaping () -> Void) {
        completion()
    }
}
