//
//  CustomerProductManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/3/22.
//

import Foundation
import SwiftUI

@MainActor
class CustomerProductManager: ObservableObject {
    @Published var customerProductData = [ProductViewModel]()
    @Published var createResponse: Bool = false
    @Published var updateResponse: Bool = false
    @Published var deleteResponse: Bool = false
    @Published var customerId: Int = -1

    var apiUrlString: String = ""

    let authManager: AuthManager

    init(customerId: Int) {
        self.customerId = customerId
        authManager = AuthManager.shared
        apiUrlString = AuthManager.baseApiUrlStr + "customerproduct"
    }

    @available(iOS 15.0, *)
    func fetchData() async throws {
        guard customerId != -1 else { return }
        guard let url = URL(string: apiUrlString + "/GetCustomerProductByCustomer/" + String(customerId)) else { return }
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
                customerProductData = try JSONDecoder().decode([ProductViewModel].self, from: data)
            } catch {
                print("JSON customer product fetch parse error \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for customerProduct fetchData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchData()
        }
    }

    @available(iOS 15.0, *)
    func postCustomerProductCreate(customerProduct: CustomerProductAddDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        createResponse = false

        let body: Data = try JSONEncoder().encode(customerProduct)

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
                createResponse = try JSONDecoder().decode(Bool.self, from: data)
                try? await fetchData()
            } catch {
                print("JSON postCustomerProductCreate parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("CustomerProduct create timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await postCustomerProductCreate(customerProduct: customerProduct)
        }
    }

    @available(iOS 15.0, *)
    func putCustomerProductUpdate(customerProduct: ProductEditDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(customerProduct.id)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        updateResponse = false

        let body: Data = try JSONEncoder().encode(customerProduct)

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
            print("CustomerProduct update timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await putCustomerProductUpdate(customerProduct: customerProduct)
        }
    }

    @available(iOS 15.0, *)
    func deleteCustomerProduct(customerProductId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(customerProductId)) else { return }

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
            guard (response as? HTTPURLResponse) != nil
            else {
                throw HttpError.badRequest
            }
            do {
                deleteResponse = try JSONDecoder().decode(Bool.self, from: data)
                try? await fetchData()
            } catch {
                print("JSON deleteCustomerProduct update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("CustomerProduct delete timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await deleteCustomerProduct(customerProductId: customerProductId)
        }
    }
}
