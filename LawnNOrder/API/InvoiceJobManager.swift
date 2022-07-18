//
//  InvoiceJobManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 5/23/22.
//

import CoreMedia
import Foundation
import SwiftUI

@MainActor
class InvoiceJobManager: ObservableObject {
    @Published var jobData = [JobViewModel]()

    @Published var invoiceId: Int = -1

    var apiUrlString: String = ""

    let authManager: AuthManager

    init(invoiceId: Int) {
        self.invoiceId = invoiceId
        authManager = AuthManager.shared
        apiUrlString = AuthManager.baseApiUrlStr + "job"
    }

    public static let shared = InvoiceManager()

    @available(iOS 15.0, *)
    func fetchData() async throws {
        guard let url = URL(string: apiUrlString + "/getjobsbyinvoice/" + String(invoiceId)) else { return }
        var request = URLRequest(url: url)
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForResource = AuthManager.readRequestTimeOut
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
                jobData = try JSONDecoder().decode([JobViewModel].self, from: data)
            } catch {
                print("JSON invoice job fetch parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for invoiceJob fetchData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchData()
        }
    }
}
