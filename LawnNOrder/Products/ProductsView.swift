//
//  ProductsView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/19/22.
//

import SwiftUI

struct ProductsView: View {
    @ObservedObject var store: GWSPersistentStore
    @ObservedObject var productFetcher: ProductManager

    var viewer: GWSUser?
    var appConfig: GWSConfigurationProtocol

    @State private var didAppear: Bool = false

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(store: GWSPersistentStore, viewer: GWSUser?, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        productFetcher = ProductManager.shared
    }

    var body: some View {
        NavigationView {
            List(productFetcher.productData) { product in
                NavigationLink {
                    ProductEditView(product: product)
                }
                label: {
                    ProductRowView(product: product)
                }
            }.refreshable {
                print("getting products on view refresh")
                try? await self.productFetcher.fetchData()
            }
            .toolbar {
                NavigationLink {
                    ProductAddView()
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
            .navigationTitle("Products")
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if !self.didAppear {
                self.didAppear = true
                Task {
                    print("getting products on view appear")
                    try? await self.productFetcher.fetchData()
                }
            }
        }
        .task {
            print("getting products on view task")
            try? await self.productFetcher.fetchData()
        }
    }
}
