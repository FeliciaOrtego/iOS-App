//
//  JobScheduleView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 3/24/22.
//

import SwiftUI

struct JobRouteOrderView: View {
    @State private var teamId: Int = -1
    @State private var updateSuccess: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    @ObservedObject var store: GWSPersistentStore
    var viewer: GWSUser?
    var appConfig: GWSConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    private let numberFormatter: NumberFormatter
    private let dateFormatter: DateFormatter

    @ObservedObject var authManager: AuthManager
    @ObservedObject var jobFetcher: JobManager
    @ObservedObject var teamFetcher: TeamManager

    init(store: GWSPersistentStore, viewer: GWSUser?, appConfig: GWSConfigurationProtocol,
         teamId: Int)
    {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "YYYY-MM-dd"
        authManager = AuthManager.shared
        jobFetcher = JobManager.shared
        teamFetcher = TeamManager.shared
        _teamId = State(initialValue: teamId)
    }

    @State public var sortDate = Date()

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    HStack {
                        Text("Select Team: ".localizedCore)
                        Picker("Team", selection: $teamId) {
                            ForEach(teamFetcher.teamData) { team in
                                Text(team.name)
                                    .tag(team.id)
                            }
                        }.pickerStyle(MenuPickerStyle.menu)
                    }
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    DatePicker(
                        "Date",
                        selection: $sortDate,
                        displayedComponents: [.date]
                    )
                }
                .padding().textFieldStyle(.roundedBorder)
                List {
                    ForEach(jobFetcher.jobData) { job in
                        if job.teamId == self.teamId &&
                            job.serviceDate == dateFormatter.string(from: self.sortDate) &&
                            job.statusCd == "A"
                        {
                            JobRowView(job: job, isSkinny: true).onDrag { NSItemProvider() }
                                .environment(\.defaultMinListRowHeight, 50)
                        }
                    }.onMove(perform: routeReOrder)
                }
            }
        }
        .alert("Jobs Updated", isPresented: $updateSuccess) {
            Button("OK") {}
        }
        .navigationTitle("Daily Route Order")
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(self.showProgress ? 1 : 0)
        )
    }

    private func routeReOrder(from source: IndexSet, to destination: Int) {
        jobFetcher.jobData.move(fromOffsets: source, toOffset: destination)
        Task(priority: .high) {
            var jobIds = [Int]()
            var routeOrders = [Int]()
            var serviceDates = [String]()
            var statusCds = [String]()

            var jobsToReOrder: [JobViewModel] = .init()
            for job: JobViewModel in self.jobFetcher.jobData {
                if job.teamId == self.teamId,
                   job.serviceDate == dateFormatter.string(from: self.sortDate),
                   job.statusCd == "A"
                {
                    jobsToReOrder.append(job)
                }
            }

            print("jobsToReOrder is \(jobsToReOrder)")

            for job in jobsToReOrder {
                jobIds.append(job.id)
                routeOrders.append(jobsToReOrder.firstIndex(of: job)! + 1)
                serviceDates.append(job.serviceDate)
                statusCds.append(job.statusCd ?? "")
            }
            print("JobIds: \(jobIds)")
            print("routeOrders: \(routeOrders)")

            try? await self.jobFetcher.postJobReOrder(
                jobIds: jobIds,
                routeOrders: routeOrders,
                serviceDates: serviceDates,
                statusCds: statusCds
            )
            print("jobFetcher updateResponse on view: \(JobManager.shared.updateResponse)")
            self.updateSuccess = jobFetcher.updateResponse
        }
    }
}
