//
//  ReportsView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/20/22.
//

import SwiftUI

struct ReportsView: View {
    @ObservedObject var store: GWSPersistentStore
    var viewer: GWSUser?
    var appConfig: GWSConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false
    @State private var yearlyTotal = 0

    @ObservedObject var invoiceFetcher: InvoiceManager

    init(store: GWSPersistentStore, viewer: GWSUser?, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        invoiceFetcher = InvoiceManager.shared
    }

    var body: some View {
        NavigationView {
            ReportsTableView(reports: self.invoiceFetcher.reportData, yearlyTotal: self.yearlyTotal)
                .navigationTitle("Reports")
                .task {
                    print("getting reports on view task")
                    try? await self.invoiceFetcher.fetchReportData()
                    yearlyTotal = 0
                    for report in self.invoiceFetcher.reportData {
                        self.yearlyTotal = self.yearlyTotal + report.monthTotal
                    }
                    print("Yearly total: \(self.yearlyTotal)")
                }
                .onAppear {
                    if !self.didAppear {
                        self.didAppear = true
                        Task {
                            print("getting reports on view appear")
                            self.showProgress = true
                            try? await self.invoiceFetcher.fetchReportData()
                            yearlyTotal = 0
                            for report in self.invoiceFetcher.reportData {
                                self.yearlyTotal = self.yearlyTotal + report.monthTotal
                            }
                            self.showProgress = false
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
        }.navigationViewStyle(.stack)
    }
}

struct ReportsTableView: View {
    let reports: [ReportViewModel]
    let columns: [GridItem] = Array(repeating: .init(.flexible(minimum: 20)), count: 5)
    let titles = ["Month", "Total", "Paid", "Unpaid", "Past Due"]
    private let numberFormatter: NumberFormatter

    let yearlyTotal: Int

    init(reports: [ReportViewModel], yearlyTotal: Int) {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 0

        self.reports = reports
        self.yearlyTotal = yearlyTotal
    }

    var body: some View {
        VStack {
            LazyVGrid(columns: columns, alignment: .center) {
                Section {
                    ForEach(0 ..< titles.count, id: \.self) { value in
                        Text(String(titles[value]))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }.frame(alignment: .top)
                    .padding(.bottom)
                Section {
                    ForEach(self.reports) { report in
                        Text(String(report.monthNameShort))
                            .fontWeight(.bold)
                        Text(self.numberFormatter.string(from: Float(report.monthTotal) / 100 as NSNumber) ?? "0.00")
                        Text(self.numberFormatter.string(from: Float(report.paid) / 100 as NSNumber) ?? "0.00")
                        Text(self.numberFormatter.string(from: Float(report.unPaid) / 100 as NSNumber) ?? "0.00")
                        Text(self.numberFormatter.string(from: Float(report.pastDue) / 100 as NSNumber) ?? "0.00")
                    }.frame(minHeight: 20, idealHeight: 30, maxHeight: 40)
                }
            }
            Section {
                Text("Yearly Total: " + (self.numberFormatter.string(from: Float(self.yearlyTotal) / 100 as NSNumber) ?? "0.00"))
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
    }
}
