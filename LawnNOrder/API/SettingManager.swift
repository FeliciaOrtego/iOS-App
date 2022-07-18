//
//  SettingManager.swift
//  LawnNOrder
//
//  Created by Felicia Ortego on 6/15/22.
//

import Foundation

@MainActor
class SettingManager: ObservableObject {
    @Published var settingData = [SettingViewModel]()
    @Published var updateResponse: Bool = false

    var apiUrlString: String = ""

    let authManager: AuthManager

    init() {
        authManager = AuthManager.shared
        apiUrlString = AuthManager.baseApiUrlStr + "applicationsetting"
    }

    public static let shared = SettingManager()

    @available(iOS 15.0, *)
    func fetchData() async throws {
        guard let url = URL(string: apiUrlString) else { return }
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
                settingData = try JSONDecoder().decode([SettingViewModel].self, from: data)
            } catch {
                print("JSON setting fetch parse error \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for setting fetchData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchData()
        }
    }

    @available(iOS 15.0, *)
    func putFooterUpdate(text: String) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/footertext") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        updateResponse = false

        let body: Data = try JSONEncoder().encode(text)

        print("JSON Product body: \(body)")

        request.httpBody = body

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
                print("JSON CustomerProduct update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("Setting update timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await putFooterUpdate(text: text)
        }
    }
}
