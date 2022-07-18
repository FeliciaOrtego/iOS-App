//
//  JobProductManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 4/10/22.
//

import Foundation
import SwiftUI

@MainActor
class JobProductManager: ObservableObject {
    @Published var jobProductData = [ProductViewModel]()
    @Published var createResponse: Bool = false
    @Published var updateResponse: Bool = false
    @Published var deleteResponse: Bool = false
    @Published var updateFailed: Bool = false

    var jobId: Int = -1

    var apiUrlString: String = ""

    let authManager: AuthManager

    init(jobId: Int) {
        self.jobId = jobId
        authManager = AuthManager.shared
        apiUrlString = AuthManager.baseApiUrlStr + "jobproduct"
    }

    @available(iOS 15.0, *)
    func fetchData() async throws {
        guard jobId != -1 else { return }
        guard let url = URL(string: apiUrlString + "/GetJobProductsByJob/" + String(jobId)) else { return }
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
                jobProductData = try JSONDecoder().decode([ProductViewModel].self, from: data)
            } catch {
                print("JSON job product fetch parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for jobProduct fetchData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchData()
        }
    }

    @available(iOS 15.0, *)
    func postJobProductCreate(jobProduct: JobProductAddDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(jobProduct)
        request.httpBody = body

        createResponse = false

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 2.0
        sessionConfig.timeoutIntervalForResource = 2.0
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
                try? await fetchData()
            } catch {
                print("JSON jobProduct create parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("jobProduct create timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await postJobProductCreate(jobProduct: jobProduct)
        }
    }

    @available(iOS 15.0, *)
    func putProductUpdate(jobProduct: ProductViewModel) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(jobProduct.id)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(jobProduct)

        request.httpBody = body

        print("JSON jobProduct body: \(body)")

        updateResponse = false

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 2.0
        sessionConfig.timeoutIntervalForResource = 2.0
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
                print("JSON jobProduct update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("jobProduct update timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await putProductUpdate(jobProduct: jobProduct)
        }
    }

    @available(iOS 15.0, *)
    func deleteProduct(jobProductId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(jobProductId)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        deleteResponse = false

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 2.0
        sessionConfig.timeoutIntervalForResource = 2.0
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
                print("JSON jobProduct delete parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("jobProduct delete timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await deleteProduct(jobProductId: jobProductId)
        }
    }
}
