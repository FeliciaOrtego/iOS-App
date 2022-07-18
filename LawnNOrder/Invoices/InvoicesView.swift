//
//  InvoicesView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/20/22.
//

import Foundation
import SwiftUI

struct InvoicesView: View {
    @ObservedObject var store: GWSPersistentStore
    @ObservedObject var invoiceFetcher: InvoiceManager

    var viewer: GWSUser?
    var appConfig: GWSConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var sendSuccess: Bool = false
    @State private var finalizeSuccess: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    init(store: GWSPersistentStore, viewer: GWSUser?, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        invoiceFetcher = InvoiceManager.shared
    }

    @State var tabIndex = 0
    @State var statusCode = "X"

    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: 30) {
                    TabBarButton(text: "Draft".localizedCore, isSelected: .constant(tabIndex == 0))
                        .onTapGesture {
                            onButtonTapped(index: 0)
                            self.statusCode = "X"
                        }
                    TabBarButton(text: "Final".localizedCore, isSelected: .constant(tabIndex == 1))
                        .onTapGesture {
                            onButtonTapped(index: 1)
                            self.statusCode = "F"
                        }
                    TabBarButton(text: "Sent".localizedCore, isSelected: .constant(tabIndex == 2))
                        .onTapGesture {
                            onButtonTapped(index: 2)
                            self.statusCode = "S"
                        }
                    TabBarButton(text: "Past Due".localizedCore, isSelected: .constant(tabIndex == 3))
                        .onTapGesture {
                            onButtonTapped(index: 3)
                            self.statusCode = "D"
                        }
                    TabBarButton(text: "Paid".localizedCore, isSelected: .constant(tabIndex == 4))
                        .onTapGesture {
                            onButtonTapped(index: 4)
                            self.statusCode = "P"
                        }
                }
                .border(width: 1, edges: [.bottom], color: .black)
                .padding()
                List {
                    ForEach(invoiceFetcher.invoiceData) { invoice in
                        if invoice.statusCd == self.statusCode {
                            NavigationLink {
                                InvoiceDetailView(store: store, appConfig: appConfig, invoice: invoice)
                            }
                            label: {
                                InvoiceRowView(invoice: invoice)
                            }
                        }
                    }
                }.refreshable {
                    try? await self.invoiceFetcher.fetchData()
                }
            }
            .navigationTitle("Invoices")
            .toolbar {
                HStack {
                    NavigationLink {
                        JobAddView(customerId: -1, customer: CustomerViewModel.defaultCustomer, isSchedule: false, isInvoiceInitialJob: true, invoiceId: -1)
                    }
                label: {
                        VStack {
                            Text("Add".localizedCore)
                                .contentShape(Rectangle())
                                .padding(5)
                            Image(systemName: "plus")
                        }
                    }
                    /* Button("Print All".localizedCore, action: printAllInvoices) */
                    if self.statusCode == "X" {
                        Button("Finalize All".localizedCore, action: finalizeAllInvoices)
                    }
                    if self.statusCode == "F" {
                        Button("Send All".localizedCore, action: sendAllInvoices)
                    }
                    if self.statusCode == "S" {
                        Button("Re-Send All".localizedCore, action: reSendAllInvoices)
                    }
                }
            }
            .alert("Invoices Sent".localizedCore, isPresented: $sendSuccess) {
                Button("OK") {
                    self.sendSuccess = false
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            .alert("Invoices Finalized".localizedCore, isPresented: $finalizeSuccess) {
                Button("OK") {
                    self.finalizeSuccess = false
                    self.presentationMode.wrappedValue.dismiss()
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
            .task {
                print("getting invoices on view task")
                try? await self.invoiceFetcher.fetchData()
            }
            .onAppear {
                if !self.didAppear {
                    self.didAppear = true
                    if self.invoiceFetcher.invoiceData.count == 0 { self.showProgress = true }
                    Task {
                        print("getting invoices on view appear")
                        try? await self.invoiceFetcher.fetchData()
                        self.showProgress = false
                    }
                }
            }
        }.navigationViewStyle(.stack)
    }

    private func onButtonTapped(index: Int) {
        withAnimation { tabIndex = index }
    }

    func printAllInvoices() {}
    func sendAllInvoices() {
        var invoiceIds = [Int]()

        for invoice in invoiceFetcher.invoiceData {
            if invoice.statusCd == "F" {
                invoiceIds.append(invoice.id)
            }
        }

        print("sending invoices: \(invoiceIds)")
        Task(priority: .low) {
            try? await self.invoiceFetcher.sendAllInvoice(invoiceIds: invoiceIds)
            self.sendSuccess = self.invoiceFetcher.sendResponse
        }
    }

    func reSendAllInvoices() {
        var invoiceIds = [Int]()

        for invoice in invoiceFetcher.invoiceData {
            if invoice.statusCd == "S" {
                invoiceIds.append(invoice.id)
            }
        }

        print("re sending invoices: \(invoiceIds)")
        Task(priority: .low) {
            try? await self.invoiceFetcher.sendAllInvoice(invoiceIds: invoiceIds)
            self.sendSuccess = self.invoiceFetcher.sendResponse
        }
    }

    func finalizeAllInvoices() {
        var invoiceIds = [Int]()

        for invoice in invoiceFetcher.invoiceData {
            if invoice.statusCd == "X" {
                invoiceIds.append(invoice.id)
            }
        }

        print("finalizing invoices: \(invoiceIds)")
        Task(priority: .low) {
            try? await self.invoiceFetcher.finalizeAllInvoice(invoiceIds: invoiceIds)
            self.finalizeSuccess = self.invoiceFetcher.updateResponse
        }
    }
}
