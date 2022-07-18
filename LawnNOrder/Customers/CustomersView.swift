//
//  HomeView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/20/22.
//

// https://developer.apple.com/documentation/swiftui/list

import SwiftUI

struct CustomersView: View {
    @ObservedObject var store: GWSPersistentStore
    @ObservedObject var customerFetcher: CustomerManager

    @State private var didAppear: Bool = false

    var viewer: GWSUser?
    var appConfig: GWSConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(store: GWSPersistentStore, viewer: GWSUser?, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        customerFetcher = CustomerManager.shared
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(customerFetcher.customerData) { customer in
                    NavigationLink {
                        CustomerDetailView(customer: customer)
                    }
                    label: {
                        CustomerRowView(customer: customer)
                    }
                }
            }
            .refreshable {
                print("getting customers on view refresh")
                try? await self.customerFetcher.fetchData()
            }
            .toolbar {
                NavigationLink {
                    CustomerAddView()
                }
                label: {
                    VStack {
                        Text("Add".localizedCore)
                            .contentShape(Rectangle())
                            .padding(5)
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle("Customers")
            .onAppear {
                if !self.didAppear {
                    self.didAppear = true
                    Task {
                        print("getting customers on view appear")
                        try? await self.customerFetcher.fetchData()
                    }
                }
            }
            .task {
                print("getting customers on view task")
                try? await self.customerFetcher.fetchData()
            }
        }.navigationViewStyle(.stack)
    }
}
