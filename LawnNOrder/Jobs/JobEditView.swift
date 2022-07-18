//
//  JobEditView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/23/22.
//

import Foundation
import SwiftUI

struct JobEditView: View {
    let job: JobViewModel
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var jobFetcher: JobManager
    @ObservedObject var teamFetcher: TeamManager

    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false
    @State private var updateSuccess: Bool = false
    @State private var teamId: Int = -1
    private let dateFormatter: DateFormatter
    @State public var serviceDate: Date = .init()
    @State public var serviceCompleteDate: Date = .init()

    init(job: JobViewModel) {
        self.job = job
        jobFetcher = JobManager.shared
        teamFetcher = TeamManager.shared
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "YYYY-MM-dd"
        _teamId = State(initialValue: job.teamId)
        if dateFormatter.date(from: self.job.serviceDate) != nil {
            _serviceDate = State(initialValue: dateFormatter.date(from: self.job.serviceDate) ?? Date())
        }
        if dateFormatter.date(from: self.job.serviceCompleteDate ?? "0000-00-00") != nil {
            _serviceCompleteDate = State(initialValue: dateFormatter.date(from: self.job.serviceCompleteDate ?? "0000-00-00") ?? Date())
        }
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    HStack {
                        Text("Select Team: ")
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
                        "Scheduled Date: ".localizedCore,
                        selection: $serviceDate,
                        displayedComponents: [.date]
                    )
                }
                .padding().textFieldStyle(.roundedBorder)
                if self.job.statusCd == "P" {
                    VStack {
                        DatePicker(
                            "Completed Date: ".localizedCore,
                            selection: $serviceCompleteDate,
                            displayedComponents: [.date]
                        )
                    }
                    .padding().textFieldStyle(.roundedBorder)
                }
                Button(action: {
                    Task(priority: .high) {
                        let svcCompleteDate: String? = self.job.statusCd == "P" ? dateFormatter.string(from: serviceCompleteDate) : nil

                        let putData: JobEditDTO = .init(
                            id: job.id,
                            companyId: 1,
                            customerId: self.job.customerId,
                            serviceDate: dateFormatter.string(from: serviceDate),
                            serviceCompleteDate: svcCompleteDate,
                            frequency: self.job.frequency,
                            teamId: self.teamId,
                            invoiceId: self.job.invoiceId,
                            statusCd: self.job.statusCd,
                            description: self.job.description
                        )

                        print("pre-flight putData: \(putData)")

                        self.showProgress = true
                        try? await jobFetcher.putJobUpdate(job: putData)
                        print("jobFetcher updateResponse on view: \(jobFetcher.updateResponse)")
                        self.showProgress = false
                        self.updateSuccess = jobFetcher.updateResponse
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Job Updated", isPresented: $updateSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationTitle("Edit Job".localizedCore)
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(self.showProgress ? 1 : 0)
        )
    }
}
