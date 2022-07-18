//
//  ProductManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/3/22.
//

import Foundation
import SwiftUI

@MainActor
class ProductManager: ObservableObject {
    @Published var productData = [ProductViewModel]()
    @Published var createResponse: Bool = false
    @Published var updateResponse: Bool = false
    @Published var deleteResponse: Bool = false

    var apiUrlString: String = ""

    let authManager: AuthManager

    init() {
        authManager = AuthManager.shared
        apiUrlString = AuthManager.baseApiUrlStr + "product"
    }

    public static let shared = ProductManager()

    @available(iOS 15.0, *)
    func fetchData() async throws {
        guard let url = URL(string: apiUrlString + "/GetProductsByCompany/1") else { return }
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
                productData = try JSONDecoder().decode([ProductViewModel].self, from: data)
            } catch {
                print("JSON product fetch parse error \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for product fetchData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchData()
        }
    }

    @available(iOS 15.0, *)
    func postProductCreate(product: ProductAddDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(product)
        request.httpBody = body

        createResponse = false

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
                createResponse = try JSONDecoder().decode(Bool.self, from: data)
                try? await fetchData()
            } catch {
                print("JSON product postProductCreate parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("product create timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await postProductCreate(product: product)
        }
    }

    @available(iOS 15.0, *)
    func putProductUpdate(product: ProductEditDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(product.id)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(product)

        request.httpBody = body

        print("JSON Product body: \(body)")

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
                print("JSON product update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("product update timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await putProductUpdate(product: product)
        }
    }

    @available(iOS 15.0, *)
    func deleteProduct(productId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(productId)) else { return }

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
                print("JSON product delete parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("product delete timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await deleteProduct(productId: productId)
        }
    }
}
