//
//  JobManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/3/22.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class JobManager: ObservableObject {
    @Published var jobData = [JobViewModel]()
    @Published var createResponse: Bool = false
    @Published var updateResponse: Bool = false
    @Published var deleteResponse: Bool = false
    var apiUrlString: String = ""

    let authManager: AuthManager

    init() {
        authManager = AuthManager.shared
        apiUrlString = AuthManager.baseApiUrlStr + "job"
    }

    public static let shared = JobManager()

    @available(iOS 15.0, *)
    func fetchData() async throws {
        guard let url = URL(string: apiUrlString + "/GetJobsByCompany/1") else { return }
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
                jobData = try JSONDecoder().decode([JobViewModel].self, from: data)
            } catch {
                print("JSON job fetch parse \(error)")
            }
        } catch URLError.timedOut {
            print("request timed out for job fetchData RETRYING...")
            session.delegateQueue.cancelAllOperations()
            try? await fetchData()
        }
    }

    @available(iOS 15.0, *)
    func postJobCreate(job: JobDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(job)

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
                print("JSON postJobCreate update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("job create timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await postJobCreate(job: job)
        }
    }

    @available(iOS 15.0, *)
    func postScheduleCreate(job: JobDTO) async
        throws
    {
        guard let url = URL(string: AuthManager.baseApiUrlStr + "customerSchedule") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(job)

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
                print("JSON postScheduleCreate update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("job schedule create timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await postScheduleCreate(job: job)
        }
    }

    @available(iOS 15.0, *)
    func postJobReOrder(jobIds: [Int], routeOrders: [Int], serviceDates: [String],
                        statusCds: [String]) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/reorderdailyjobs") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let reOrderDTO = JobsReOrderDTO(
            jobIds: jobIds,
            routeOrders: routeOrders,
            serviceDates: serviceDates,
            statusCds: statusCds
        )

        let body: Data = try JSONEncoder().encode(reOrderDTO)
        print("JSON JobReOrder body: \(body)")

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
                print("JSON Job reOrder parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("job re-order timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await postJobReOrder(jobIds: jobIds, routeOrders: routeOrders, serviceDates: serviceDates, statusCds: statusCds)
        }
    }

    @available(iOS 15.0, *)
    func putJobUpdate(job: JobEditDTO) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(job.id)) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.setValue(authManager.accessToken, forHTTPHeaderField: "Authorization")

        let body: Data = try JSONEncoder().encode(job)

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
                print("JSON Job update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("job update timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await putJobUpdate(job: job)
        }
    }

    @available(iOS 15.0, *)
    func completeOrSkipJob(jobId: Int, statusCd: String) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/completeorskip/" + String(jobId) + "/" + statusCd) else { return }
        var request = URLRequest(url: url)
        request.setValue(AuthManager.shared.accessToken, forHTTPHeaderField: "Authorization")

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
                print("JSON completeOrSkipJob update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("job completeOrSkip timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await completeOrSkipJob(jobId: jobId, statusCd: statusCd)
        }
    }

    @available(iOS 15.0, *)
    func deleteJobByCustomer(customerId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/schedule/" + String(customerId)) else { return }

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
                print("JSON deleteJobByCustomer update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("job deleteJobByCustomer timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await deleteJobByCustomer(customerId: customerId)
        }
    }

    @available(iOS 15.0, *)
    func deleteJob(jobId: Int) async
        throws
    {
        guard let url = URL(string: apiUrlString + "/" + String(jobId)) else { return }

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
                print("JSON deleteJob update parse error: \(error)")
            }
        } catch URLError.timedOut {
            print("job delete timeout error")
            session.delegateQueue.cancelAllOperations()
            try? await deleteJob(jobId: jobId)
        }
    }
}
