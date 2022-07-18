//
//  JobsView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/20/22.
//

import Foundation
import SwiftUI

struct JobsView: View {
    @ObservedObject var store: GWSPersistentStore

    @ObservedObject var authManager: AuthManager
    @ObservedObject var teamFetcher: TeamManager
    @ObservedObject var jobFetcher: JobManager

    @State private var didAppear: Bool = false
    @State private var showProgress: Bool = false

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var viewer: GWSUser?
    var appConfig: GWSConfigurationProtocol

    private let dateFormatter: DateFormatter

    @State private var teamId: Int = 1

    init(store: GWSPersistentStore, viewer: GWSUser?, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "YYYY-MM-dd"
        authManager = AuthManager.shared
        teamFetcher = TeamManager.shared
        jobFetcher = JobManager.shared
    }

    @State private var tabIndex = 0
    @State private var statusCode = "A"

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    HStack {
                        Text("Select Team: ".localizedCore)
                        Picker("Team", selection: $teamId) {
                            ForEach(teamFetcher.teamData) { team in
                                Text(team.name)
                                    .tag(team.id)
                            }
                        }.pickerStyle(MenuPickerStyle.menu).disabled(self.authManager.isAdmin == false)
                    }
                }
                HStack(spacing: 20) {
                    TabBarButton(text: "Current", isSelected: .constant(tabIndex == 0))
                        .onTapGesture {
                            onButtonTapped(index: 0)
                            self.statusCode = "A"
                        }

                    if store.userIfLoggedInUser() != nil && self.authManager.isAdmin == true {
                        TabBarButton(text: "Skipped", isSelected: .constant(tabIndex == 1))
                            .onTapGesture {
                                onButtonTapped(index: 1)
                                self.statusCode = "S"
                            }
                        TabBarButton(text: "Next", isSelected: .constant(tabIndex == 2))
                            .onTapGesture {
                                onButtonTapped(index: 2)
                                self.statusCode = "N"
                            }
                    }
                }
                .border(width: 1, edges: [.bottom], color: .black)
                .padding()
                .navigationTitle("Jobs".localizedCore)
                List {
                    ForEach(jobFetcher.jobData) { job in
                        if job.statusCd == self.statusCode &&
                            job.teamId == self.teamId
                        {
                            NavigationLink {
                                JobDetailView(store: store, appConfig: appConfig, job: job)
                            }
                                label: {
                                JobRowView(job: job, isSkinny: false)
                            }
                        }
                    }
                }.refreshable {
                    print("getting jobs and teams on view refresh")
                    try? await self.jobFetcher.fetchData()
                    Task(priority: .high) {
                        try? await self.teamFetcher.fetchData()
                    }
                }.overlay(
                    VStack {
                        CPKProgressHUDSwiftUI()
                    }
                    .frame(width: 100,
                           height: 100)
                    .opacity(self.showProgress ? 1 : 0)
                )
                .toolbar {
                    if store.userIfLoggedInUser() != nil && self.authManager.isAdmin == true {
                        HStack {
                            NavigationLink {
                                JobAddView(customerId: -1, customer: CustomerViewModel.defaultCustomer, isSchedule: true, isInvoiceInitialJob: false, invoiceId: -1)
                            }
                    label: {
                                VStack {
                                    Text("Add".localizedCore)
                                        .contentShape(Rectangle())
                                        .padding(5)
                                    Image(systemName: "plus")
                                }
                            }
                            NavigationLink {
                                JobRouteOrderView(store: self.store, viewer: self.viewer, appConfig: self.appConfig, teamId: teamId)
                            }
                    label: {
                                Text("Set Routes")
                            }
                        }
                    }
                }
            }.navigationTitle("Jobs".localizedCore)
        }
        .navigationViewStyle(.stack)
        .task {
            if store.userIfLoggedInUser() != nil && self.authManager.isAdmin == false {
                self.teamId = self.authManager.userTeamId
            }
        }
        .onAppear {
            if !self.didAppear {
                self.didAppear = true
                if self.jobFetcher.jobData.count == 0 { self.showProgress = true }
                Task {
                    print("geting teams and jobs task")
                    try? await self.teamFetcher.fetchData()
                    Task(priority: .high) {
                        try? await self.jobFetcher.fetchData()
                        self.showProgress = false
                    }
                }
            }
        }
        .task {
            print("geting teams and jobs task")
            try? await self.teamFetcher.fetchData()
            Task(priority: .high) {
                try? await self.jobFetcher.fetchData()
            }
        }
    }

    private func onButtonTapped(index: Int) {
        withAnimation { tabIndex = index }
    }
}
