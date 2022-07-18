//
//  InvoiceManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/3/22.
//

import Foundation
import SwiftUI

@MainActor
class InvoiceManager: ObservableObject {
    @Published var invoiceData = [InvoiceViewModel]()
    @Published var reportData = [ReportViewModel]()

    @Published var createResponse: Bool = false
    @Published var updateResponse: Bool = false
    @Published var deleteResponse: Bool = false
    @Published var sendResponse: Bool = false
    @Published var finalizeResponse: Bool = false

    @Published var invoiceId: Int = -1

    var apiUrlString: String = ""

    let authManager: AuthManager

    init() {
        authManager = AuthManager.shared
        apiUrlString = AuthManager.baseApiUrlStr + "invoice"
    }

    public static let shared = InvoiceManager()

    @available(iOS 15.0, *)
    func fetchData() async throws {
        guard let url = URL(string: apiUrlString + "/getinvoicesbycompany/1") else { return }
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
                invoiceData = try JSONDecoder().decode([InvoiceViewModel].self, from: data)
            } catch {
                print("JSON invoice fetch parse \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for invoice fetchData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchData()
        }
    }

    @available(iOS 15.0, *)
    func fetchReportData() async throws {
        // TODO: make a selector for this to view other years, API can handle it
        let year = "2022"
        guard let url = URL(string: apiUrlString + "/reports/1/" + year) else { return }
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
                reportData = try JSONDecoder().decode([ReportViewModel].self, from: data)
            } catch {
                print("JSON reports fetch parse \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for reports fetchReportData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchReportData()
        }
    }

    @available(iOS 15.0, *)
    func sendInvoice(invoiceId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/send/" + String(invoiceId)) else { return }
        var request = URLRequest(url: url)
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        print("Invoice send request: \(request)")

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = AuthManager.sendRequestTimeOut
        sessionConfig.timeoutIntervalForResource = AuthManager.sendRequestTimeOut
        sessionConfig.waitsForConnectivity = true
        let session = URLSession(configuration: sessionConfig)

        sendResponse = false

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                throw HttpError.badRequest
            }
            do {
                sendResponse = try JSONDecoder().decode(Bool.self, from: data)
                try? await fetchData()
            } catch {
                sendResponse = false
                print("JSON sendInvoice parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("invoice send timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await sendInvoice(invoiceId: invoiceId)
        }
    }

    @available(iOS 15.0, *)
    func sendAllInvoice(invoiceIds: [Int]) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/send") else { return }
        var request = URLRequest(url: url)
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        print("Invoice send request: \(request)")

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = AuthManager.sendAllInvoiceRequestTimeOut
        sessionConfig.timeoutIntervalForResource = AuthManager.sendAllInvoiceRequestTimeOut
        sessionConfig.waitsForConnectivity = true
        let session = URLSession(configuration: sessionConfig)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(invoiceIds)

        request.httpBody = body

        sendResponse = false

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                throw HttpError.badRequest
            }
            do {
                sendResponse = try JSONDecoder().decode(Bool.self, from: data)
                try? await fetchData()
            } catch {
                sendResponse = false
                session.delegateQueue.cancelAllOperations()
                print("JSON sendAllInvoice parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("invoice sendMany timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await sendAllInvoice(invoiceIds: invoiceIds)
        }
    }

    @available(iOS 15.0, *)
    func finalizeAllInvoice(invoiceIds: [Int]) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/finalize") else { return }
        var request = URLRequest(url: url)
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        print("Invoice send request: \(request)")

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = AuthManager.sendAllInvoiceRequestTimeOut
        sessionConfig.timeoutIntervalForResource = AuthManager.sendAllInvoiceRequestTimeOut
        sessionConfig.waitsForConnectivity = true
        let session = URLSession(configuration: sessionConfig)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(invoiceIds)

        request.httpBody = body

        updateResponse = false

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
                updateResponse = false
                session.delegateQueue.cancelAllOperations()
                print("JSON finalizeAllInvoice parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("invoice finalizeAllInvoice timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await finalizeAllInvoice(invoiceIds: invoiceIds)
        }
    }

    @available(iOS 15.0, *)
    func postInvoiceCreate(invoice: InvoiceDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(invoice)

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
                print("JSON postInvoiceCreate parse error: \(error)")
                createResponse = false
            }
        } catch URLError.timedOut {
            print("invoice create timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await postInvoiceCreate(invoice: invoice)
        }
    }

    @available(iOS 15.0, *)
    func putInvoiceFinalize(invoiceId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/finalize/" + String(invoiceId)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        finalizeResponse = false

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = AuthManager.finalizeInvoiceRequestTimeOut
        sessionConfig.timeoutIntervalForResource = AuthManager.finalizeInvoiceRequestTimeOut
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
                finalizeResponse = try JSONDecoder().decode(Bool.self, from: data)
                try? await fetchData()
            } catch {
                print("JSON putInvoiceFinalize parse error: \(error)")
                finalizeResponse = false
            }
        } catch URLError.timedOut {
            print("invoice finalize timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await putInvoiceFinalize(invoiceId: invoiceId)
        }
    }

    @available(iOS 15.0, *)
    func putInvoiceUpdate(invoice: InvoiceEditDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(invoice.id)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(invoice)

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
                print("JSON putInvoiceUpdate parse error: \(error)")
                updateResponse = false
            }
        } catch URLError.timedOut {
            print("invoice update timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await putInvoiceUpdate(invoice: invoice)
        }
    }

    @available(iOS 15.0, *)
    func deleteInvoice(invoiceId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(invoiceId)) else { return }

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
                print("JSON deleteInvoice parse error: \(error)")
                deleteResponse = false
            }
        } catch URLError.timedOut {
            print("invoice delete timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await deleteInvoice(invoiceId: invoiceId)
        }
    }
}
