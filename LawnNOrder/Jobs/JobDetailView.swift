//
//  JobDetail.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/27/22.
//

import SwiftUI

struct JobDetailView: View {
    var job: JobViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) var openURL

    @ObservedObject var store: GWSPersistentStore
    var appConfig: GWSConfigurationProtocol
    @State private var updateSuccess: Bool = false
    @State private var deleteSuccess: Bool = false

    @ObservedObject var jobFetcher: JobManager

    @State private var isSkippingJob: Bool = false
    @State private var hasSubmittedSkipReason: Bool = false
    @State private var jobProducts = [ProductViewModel]()
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    @State private var skipReason: String = "lack of growth".localizedCore

    private let numberFormatter: NumberFormatter
    private let dateFormatter: DateFormatter
    @State private var serviceCompleteDate = Date()
    @State private var changedAddress: String?
    @State var selection: Int? = nil

    @ObservedObject var authManager: AuthManager

    init(store: GWSPersistentStore, appConfig: GWSConfigurationProtocol, job: JobViewModel) {
        self.store = store
        self.appConfig = appConfig
        self.job = job
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "YYYY-MM-dd"
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        authManager = AuthManager.shared
        jobFetcher = JobManager.shared
        _jobProducts = State(initialValue: job.products ?? [ProductViewModel]())
    }

    var body: some View {
        let frqStr: String = job.frequency != 0 ?
            job.frequency == 2 ? "Bi-Weekly" :
            job.frequency > 1 ? "repeats every " + String(job.frequency) + " weeks" : "Weekly"
            : "Once"

        VStack {
            VStack {
                Text(job.customerDisplayName)
                    .font(.system(size: 24))
                Text(frqStr.localizedCore)
                    .font(.system(size: 22, weight: .light))
                Text(job.serviceDate)
                    .font(.system(size: 22, weight: .light))
                Button(action: {
                    openMap(Address: job.customerDisplayAddress)
                }) {
                    Text(job.customerDisplayAddress)
                }
                .font(.system(size: 22, weight: .bold))
                Text(job.teamNameDisplayString)
                    .font(.system(size: 20, weight: .light))
            }
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.sRGB, red: 150 / 255, green: 150 / 255, blue: 150 / 255, opacity: 0.1), lineWidth: 1)
            )
            .padding([.top, .horizontal])
            List(jobProducts) { product in
                HStack {
                    Text(product.name)

                    if self.store.userIfLoggedInUser() != nil && self.authManager.isAdmin == true {
                        Text(self.numberFormatter.string(from: Float(product.price) / 100 as NSNumber) ?? "0.00").font(.system(size: 14, weight: .light))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }.refreshable {
                let fetcher = JobProductManager(jobId: self.job.id)
                try? await fetcher.fetchData()
                self.jobProducts = fetcher.jobProductData
            }
            if job.statusCd == "A" && self.jobProducts.count > 0 {
                VStack {
                    Section {
                        Button(action: {
                            Task(priority: .high) {
                                print("completing job...")
                                self.showProgress = true
                                try? await jobFetcher.completeOrSkipJob(jobId: job.id, statusCd: "P")
                                self.showProgress = false
                                print("job update res on view: \(self.jobFetcher.updateResponse)")

                                self.updateSuccess = self.jobFetcher.updateResponse
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text("Done".localizedCore)
                                .frame(minWidth: 0, maxWidth: 120)
                                .frame(height: 35)
                                .foregroundColor(Color.white)
                                .background(Color(appConfig.mainThemeForegroundColor))
                                .cornerRadius(45 / 2)
                                .padding(.horizontal, 30)
                                .padding(10)
                        }
                        Button(action: {
                            self.isSkippingJob = true
                        }) {
                            Text("Skip".localizedCore)
                                .frame(minWidth: 0, maxWidth: 120)
                                .frame(height: 35)
                                .foregroundColor(Color.white)
                                .background(Color(appConfig.mainThemeWarnColor))
                                .opacity(!self.isSkippingJob ? 1 : 0)
                                .cornerRadius(45 / 2)
                                .padding(.horizontal, 30)
                                .padding(10)
                        }
                    }.disabled(self.isSkippingJob)
                        .opacity(self.isSkippingJob ? 0 : 1)
                        .alert(isPresented: $hasSubmittedSkipReason) {
                            Alert(
                                title: Text("Skip Job?".localizedCore),
                                primaryButton: .default(Text("Yes".localizedCore)) {
                                    skipJob()
                                },
                                secondaryButton: .cancel(Text("No".localizedCore))
                            )
                        }
                    if isSkippingJob == true {
                        VStack {
                            Text("Skip Reason?".localizedCore)
                            TextField("Text", text: self.$skipReason)
                            Divider()
                            HStack {
                                Button(action: {
                                    skipJob()
                                    withAnimation {
                                        self.isSkippingJob.toggle()
                                    }
                                }) {
                                    Text("OK".localizedCore)
                                }.padding(.trailing, 40)
                                Button(action: {
                                    withAnimation {
                                        self.isSkippingJob.toggle()
                                    }
                                }) {
                                    Text("Cancel".localizedCore)
                                }.padding(.leading, 40)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .shadow(radius: 1)
                        .opacity(self.isSkippingJob ? 1 : 0)
                    }
                }
            }
            if self.authManager.isAdmin == true {
                Spacer()
                VStack {
                    Button(action: {
                        Task(priority: .high) {
                            self.showProgress = true
                            if job.statusCd == "P" {
                                try? await jobFetcher.deleteJob(jobId: job.id)
                            } else {
                                try? await jobFetcher.deleteJobByCustomer(customerId: job.customerId)
                            }
                            self.showProgress = false
                            print("deleteResponse deleteResponse on view: \(jobFetcher.deleteResponse)")
                            self.deleteSuccess = jobFetcher.deleteResponse
                        }
                    }) {
                        DeleteButtonContent()
                    }
                    .alert("Job Deleted".localizedCore, isPresented: $deleteSuccess) {
                        Button("OK".localizedCore, role: .cancel) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }.padding()
            }
        }
        .alert("Job Updated".localizedCore, isPresented: $updateSuccess) {
            Button("OK".localizedCore) {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .toolbar {
            if self.store.userIfLoggedInUser() != nil && self.authManager.isAdmin == true {
                HStack {
                    NavigationLink {
                        JobEditView(job: job)
                    }
                    label: {
                        Text("Edit Job".localizedCore)
                    }
                    NavigationLink {
                        JobProductDetailView(job: job)
                    }
                    label: {
                        Text("Edit Products".localizedCore)
                    }
                }
            }
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(self.showProgress ? 1 : 0)
        )
        .onAppear {
            if !self.didAppear {
                self.didAppear = true
                Task {
                    let fetcher = JobProductManager(jobId: self.job.id)
                    try? await fetcher.fetchData()
                    self.jobProducts = fetcher.jobProductData
                }
            }
        }
        .task {
            let fetcher = JobProductManager(jobId: self.job.id)
            try? await fetcher.fetchData()
            self.jobProducts = fetcher.jobProductData
        }
    }

    func openMap(Address: String) {
        changedAddress = Address.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: "http://maps.apple.com/?address=\(changedAddress!)") else {
            return
        }
        openURL(url)
    }

    func skipJob() {
        Task(priority: .high) {
            print("skipping job...")

            let updatedJob = JobEditDTO(
                id: self.job.id,
                companyId: 1,
                customerId: self.job.customerId,
                serviceDate: self.job.serviceDate,
                serviceCompleteDate: dateFormatter.string(from: serviceCompleteDate),
                frequency: self.job.frequency,
                teamId: self.job.teamId,
                invoiceId: self.job.invoiceId,
                statusCd: "S",
                description: self.skipReason
            )
            self.showProgress = true
            try? await jobFetcher.completeOrSkipJob(jobId: job.id, statusCd: "S")
            try? await jobFetcher.putJobUpdate(job: updatedJob)
            self.showProgress = false
            print("job update res on view: \(self.jobFetcher.updateResponse)")
            self.updateSuccess = self.jobFetcher.updateResponse
        }
    }
}
