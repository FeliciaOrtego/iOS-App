//
//  AuthManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/12/22.
//

import Foundation
import SwiftUI

@MainActor
public class AuthManager: ObservableObject {
    @Published var loginResponse: AuthResponse = .defaultAuthResponse
    var loginRequest: AuthRequest = .defaultAuthRequest
    @Published var createResponse: Bool = false

    public static let shared = AuthManager()

    @Published public var accessToken: String = .init(data: (KeychainHelper.standard.read(service: "access-token", account: "lawn") != nil) ? KeychainHelper.standard.read(service: "access-token", account: "lawn")! : nil ?? Data(), encoding: .utf8)!

    @Published public var userTeamId: Int = (Int(String(data: (KeychainHelper.standard.read(service: "teamId", account: "lawn") != nil) ? KeychainHelper.standard.read(service: "teamId", account: "lawn")! : nil ?? Data(), encoding: .utf8)!) ?? -1)

    @Published public var isAdmin: Bool = String(data: (KeychainHelper.standard.read(service: "isAdmin", account: "lawn") != nil) ? KeychainHelper.standard.read(service: "isAdmin", account: "lawn")! : nil ?? Data(), encoding: .utf8)! == "Y" ? true : false

    public static let baseApiUrlStr: String = "https://example.com
    public static let readRequestTimeOut: Double = 8.00
    public static let writeRequestTimeOut: Double = 8.00
    public static let finalizeInvoiceRequestTimeOut: Double = 20.00
    public static let sendAllInvoiceRequestTimeOut: Double = 120.00 // 2 mins
    public static let sendRequestTimeOut: Double = 10.00

    var apiUrlString: String = ""

    init() {
        apiUrlString = AuthManager.baseApiUrlStr + "auth/"
    }

    func logOut() {
        accessToken = ""
        KeychainHelper.standard.delete(service: "access-token", account: "lawn")
        KeychainHelper.standard.delete(service: "teamId", account: "lawn")
        KeychainHelper.standard.delete(service: "isAdmin", account: "lawn")
        UserDefaults.standard.removeObject(forKey: GWSPersistentStore.kLoggedInUserKey)
    }

    @available(iOS 15.0, *)
    func postLogin(email: String, phone _: String) async
        throws
    {
        guard let url = URL(string: apiUrlString + "authenticate") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        // TODO: One of the last hard coded companyIds, need a company select at login or company specific invite token
        let loginRequest = AuthRequest(email: email, companyId: 1)
        let body: Data = try JSONEncoder().encode(loginRequest)

        request.httpBody = body

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 60.0
        sessionConfig.timeoutIntervalForResource = 60.0
        sessionConfig.waitsForConnectivity = true
        let session = URLSession(configuration: sessionConfig)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                throw HttpError.badRequest
            }

            loginResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

            print("JSON Auth loginResponse: \(loginResponse)")

            let accessResToken = loginResponse.token
            let keyChainData = Data(accessResToken.utf8)

            KeychainHelper.standard.save(keyChainData, service: "access-token", account: "lawn")
            accessToken = accessResToken

            let jwt = try decodeJWT(jwtToken: accessToken)
            print("JSON Auth success. Token Content: \(jwt)")

            let isAdminStr: String? = jwt["adminYN"] as? String
            print("JSON adminYN Content: \(String(describing: isAdminStr))")
            let roleData = Data(isAdminStr?.utf8 ?? "N".utf8)
            KeychainHelper.standard.save(roleData, service: "isAdmin", account: "lawn")

            let userTeamIdStr: String? = jwt["teamId"] as? String
            print("JSON userTeamId Content: \(String(describing: userTeamIdStr))")
            let teamData = Data(userTeamIdStr?.utf8 ?? "-1".utf8)
            KeychainHelper.standard.save(teamData, service: "teamId", account: "lawn")

            userTeamId = Int(userTeamIdStr ?? "-1") ?? -1
            print("final userTeamId: \(userTeamId)")

            isAdmin = isAdminStr == "Y" ? true : false
        } catch {
            print("Forcing logout out! Auth error: \(error)")
            logOut()
            throw HttpError.badAuth
        }
    }

    @available(iOS 15.0, *)
    func postUserCreate(user: UserDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString + "register") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(user)

        request.httpBody = body

        createResponse = false

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 6.0
        sessionConfig.timeoutIntervalForResource = 6.0
        sessionConfig.waitsForConnectivity = true
        let session = URLSession(configuration: sessionConfig)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                throw HttpError.badRequest
            }
            do {
                createResponse = try JSONDecoder().decode(Bool.self, from: data)
            } catch {
                print("JSON user create parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("user create timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await postUserCreate(user: user)
        } catch {
            print("Forcing logout out! Auth error: \(error)")
            logOut()
            throw HttpError.badAuth
        }
    }
}
