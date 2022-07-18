//
//  JobAddView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/23/22.
//

// https://developer.apple.com/documentation/swiftui/form
// https://developer.apple.com/documentation/swiftui/textfield

import SwiftUI

struct JobAddView: View {
    @Environment(\.presentationMode) var presentationMode

    let isSchedule: Bool
    let isInvoiceInitialJob: Bool
    let invoiceId: Int

    @ObservedObject var customerFetcher: CustomerManager
    @ObservedObject var jobFetcher: JobManager
    @ObservedObject var teamFetcher: TeamManager
    @ObservedObject var invoiceFetcher: InvoiceManager

    @State private var frequency: Int = 1
    @State private var teamId: Int = 1
    @State private var customerId: Int = -1

    @State private var createSuccess: Bool = false
    @State private var noProductValidationMsg: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false
    @State private var showFrequencySelect: Bool = true

    @State private var selectedIds: [Int] = .init()
    @State private var customerProducts = [ProductViewModel]()

    private let numberFormatter: NumberFormatter
    private let dateFormatter: DateFormatter
    @State public var serviceDate = Date()
    private var title: String = ""

    init(customerId: Int, customer _: CustomerViewModel?,
         isSchedule: Bool, isInvoiceInitialJob: Bool, invoiceId: Int)
    {
        self.isSchedule = isSchedule
        self.isInvoiceInitialJob = isInvoiceInitialJob
        self.invoiceId = invoiceId
        customerFetcher = CustomerManager.shared
        jobFetcher = JobManager.shared
        teamFetcher = TeamManager.shared
        customerFetcher = CustomerManager.shared
        invoiceFetcher = InvoiceManager.shared
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "YYYY-MM-dd"
        if customerId > 0 {
            self.customerId = customerId
            _customerId = State(initialValue: customerId)
        }
        if isSchedule {
            title = "Schedule Job".localizedCore
        } else if isInvoiceInitialJob {
            title = "Add Invoice".localizedCore
        } else {
            title = "Add Job to Invoice".localizedCore
        }
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    Picker("Customer", selection: $customerId) {
                        ForEach(customerFetcher.customerData) { customer in
                            Text(customer.displayName + " - " + customer.displayAddress)
                                .tag(customer.id)
                        }
                    }.onChange(of: self.customerId) {
                        _ in print("Selected Customer : \(self.customerId)")
                        print("getting products on Customer change")
                        Task(priority: .high) {
                            let fetcher = CustomerProductManager(customerId: customerId)
                            self.showProgress = true
                            try? await fetcher.fetchData()
                            self.showProgress = false
                            self.customerProducts = fetcher.customerProductData
                        }
                    }.pickerStyle(.automatic)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    DatePicker(
                        "Start Date",
                        selection: $serviceDate,
                        displayedComponents: [.date]
                    )
                }
                .padding().textFieldStyle(.roundedBorder)
                if self.isSchedule {
                    VStack {
                        Toggle("Repeat", isOn: $showFrequencySelect)
                    }.padding().textFieldStyle(.roundedBorder)
                    if showFrequencySelect == true {
                        VStack {
                            Text("Repeat every...")
                            TextField("Frequency", value: $frequency, formatter: numberFormatter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                            Text("Weeks")
                        }
                        .padding().textFieldStyle(.roundedBorder)
                    }
                }
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
                List {
                    Text("Select Products: ")
                    ForEach(self.customerProducts) { product in
                        MultipleSelectionRow(title: product.name + " ... " + String(Float(product.price) / 100), isSelected: self.selectedIds.contains(product.id)) {
                            if self.selectedIds.contains(product.id) {
                                self.selectedIds.removeAll(where: { $0 == product.id })
                            } else {
                                self.selectedIds.append(product.id)
                            }
                        }
                    }
                }
                .padding().textFieldStyle(.roundedBorder)
                .navigationTitle(self.title)
                Button(action: {
                    Task(priority: .high) {
                        if self.showFrequencySelect == false {
                            self.frequency = 0
                        }

                        if $selectedIds.count > 0 {
                            print("pre-flight serviceDate: \(serviceDate)")

                            print("pre-flight serviceDate formatted: \(dateFormatter.string(from: serviceDate))")

                            if isSchedule {
                                let postData: JobDTO = .init(
                                    customerId: self.customerId,
                                    companyId: 1,
                                    serviceDate: dateFormatter.string(from: serviceDate),
                                    frequency: self.frequency,
                                    teamId: self.teamId,
                                    invoiceId: self.invoiceId,
                                    productIds: self.selectedIds
                                )
                                self.showProgress = true
                                try? await self.jobFetcher.postScheduleCreate(job: postData)
                                self.showProgress = false
                                print("job create res on view: \(self.jobFetcher.createResponse)")
                                self.createSuccess = self.jobFetcher.createResponse
                            } else if isInvoiceInitialJob {
                                let postData: InvoiceDTO = .init(
                                    companyId: 1,
                                    customerId: self.customerId,
                                    serviceDate: dateFormatter.string(from: serviceDate),
                                    teamId: self.teamId,
                                    jobProductIds: self.selectedIds
                                )
                                self.showProgress = true
                                try? await self.invoiceFetcher.postInvoiceCreate(invoice: postData)
                                self.showProgress = false
                                print("invoice create res on view: \(self.invoiceFetcher.createResponse)")
                                self.createSuccess = self.invoiceFetcher.createResponse
                            } else {
                                let postData: JobDTO = .init(
                                    customerId: self.customerId,
                                    companyId: 1,
                                    serviceDate: dateFormatter.string(from: serviceDate),
                                    frequency: self.frequency,
                                    teamId: self.teamId,
                                    invoiceId: self.invoiceId,
                                    productIds: self.selectedIds
                                )
                                self.showProgress = true
                                try? await jobFetcher.postJobCreate(job: postData)
                                self.showProgress = false
                                print("job create res on view: \(self.jobFetcher.createResponse)")
                                self.createSuccess = self.jobFetcher.createResponse
                            }
                        } else {
                            self.noProductValidationMsg = true
                        }
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Added", isPresented: $createSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }.alert("Select a Product", isPresented: $noProductValidationMsg) {
                    Button("OK") {
                        self.noProductValidationMsg = false
                    }
                }
            }
            .onAppear {
                if !self.didAppear {
                    self.didAppear = true
                    Task {
                        let fetcher = CustomerProductManager(customerId: self.customerId)
                        try? await fetcher.fetchData()
                        self.customerProducts = fetcher.customerProductData
                    }
                }
            }
            .task {
                let fetcher = CustomerProductManager(customerId: self.customerId)
                try? await fetcher.fetchData()
                self.customerProducts = fetcher.customerProductData
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
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        return Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
