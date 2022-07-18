//
//  UserManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/3/22.
//

import Foundation
import SwiftUI

@MainActor
class UserManager: ObservableObject {
    @Published var userData = [UserViewModel]()
    @Published var createResponse: Bool = false
    @Published var updateResponse: Bool = false
    @Published var deleteResponse: Bool = false
    var apiUrlString: String = ""

    let authManager: AuthManager

    init() {
        authManager = AuthManager.shared
        apiUrlString = AuthManager.baseApiUrlStr + "user"
    }

    public static let shared = UserManager()

    @available(iOS 15.0, *)
    func fetchData() async throws {
        guard let url = URL(string: apiUrlString + "/GetUsersByCompany/1") else { return }
        var request = URLRequest(url: url)
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = AuthManager.readRequestTimeOut
        sessionConfig.timeoutIntervalForResource = AuthManager.readRequestTimeOut
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
                userData = try JSONDecoder().decode([UserViewModel].self, from: data)
            } catch {
                print("JSON user fetch parse error \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for user fetchData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchData()
        }
    }

    @available(iOS 15.0, *)
    func putUserUpdate(user: UserEditDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(user.id)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(user)

        request.httpBody = body

        updateResponse = false

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = AuthManager.writeRequestTimeOut
        sessionConfig.timeoutIntervalForResource = AuthManager.writeRequestTimeOut
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
                updateResponse = try JSONDecoder().decode(Bool.self, from: data)
                try? await fetchData()
            } catch {
                print("JSON user update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("user update timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await putUserUpdate(user: user)
        }
    }

    @available(iOS 15.0, *)
    func deleteUser(userId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(userId)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        deleteResponse = false

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = AuthManager.writeRequestTimeOut
        sessionConfig.timeoutIntervalForResource = AuthManager.writeRequestTimeOut
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
                deleteResponse = try JSONDecoder().decode(Bool.self, from: data)
                try? await fetchData()
            } catch {
                print("JSON user delete parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("user delete timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await deleteUser(userId: userId)
        }
    }
}
