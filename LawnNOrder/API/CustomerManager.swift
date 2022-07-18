//
//  CustomerManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/3/22.
//

import Foundation
import SwiftUI

@MainActor
class CustomerManager: ObservableObject {
    @Published var customerData = [CustomerViewModel]()
    @Published var createResponse: Bool = false
    @Published var updateResponse: Bool = false
    @Published var deleteResponse: Bool = false

    var apiUrlString: String = ""

    let authManager: AuthManager

    init() {
        authManager = AuthManager.shared
        apiUrlString = AuthManager.baseApiUrlStr + "customer"
    }

    public static let shared = CustomerManager()

    @available(iOS 15.0, *)
    func fetchData() async throws {
        guard let url = URL(string: apiUrlString + "/GetCustomersByCompany/1") else { return }
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
                customerData = try JSONDecoder().decode([CustomerViewModel].self, from: data)
            } catch {
                print("JSON customer fetch parse error \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for customer fetchData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchData()
        }
    }

    @available(iOS 15.0, *)
    func postCustomerCreate(customer: CustomerDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(customer)

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
                print("JSON customer create parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("customer create timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await postCustomerCreate(customer: customer)
        }
    }

    @available(iOS 15.0, *)
    func putCustomerUpdate(customer: CustomerEditDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(customer.id)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(customer)

        print("JSON customer body: \(body)")

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
                print("JSON customer update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("customer update timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await putCustomerUpdate(customer: customer)
        }
    }

    @available(iOS 15.0, *)
    func deleteCustomer(customerId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(customerId)) else { return }

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
                print("JSON customer delete parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("customer delete timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await deleteCustomer(customerId: customerId)
        }
    }
}
