//
//  JobProductEditView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 4/13/22.
//

import SwiftUI

struct JobProductAddView: View {
    let jobId: Int
    let customerId: Int

    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var productFetcher: ProductManager
    @ObservedObject var jobProductFetcher: JobProductManager
    @ObservedObject var customerProductFetcher: CustomerProductManager

    @State private var price: Float = 0
    @State private var customerProducts: [ProductViewModel] = .init()

    @State private var showCreateSuccess: Bool = false

    private let numberFormatter: NumberFormatter

    @State private var name: String = ""
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    @State private var productId: Int = 1

    init(job: JobViewModel, customerId: Int) {
        jobId = job.id
        productFetcher = ProductManager.shared
        customerProductFetcher = CustomerProductManager(customerId: job.customerId)
        jobProductFetcher = JobProductManager(jobId: jobId)
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        self.customerId = customerId
        customerProducts = customerProductFetcher.customerProductData
        if let selectedProduct = customerProducts.first(where: { $0.productId == self.productId }) {
            price = (Float(selectedProduct.price) / 100)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    HStack {
                        Picker("Select Product:", selection: $productId) {
                            ForEach(productFetcher.productData) { product in
                                Text(product.name)
                                    .tag(product.id)
                            }
                        }.onChange(of: self.productId) {
                            _ in print("Selected Product Id : \(String(self.productId))")
                            print("getting default price on Product change")
                            Task(priority: .high) {
                                let fetcher = CustomerProductManager(customerId: self.customerId)
                                self.showProgress = true
                                try? await fetcher.fetchData()
                                self.showProgress = false
                                self.customerProducts = fetcher.customerProductData
                                if let selectedProduct = self.customerProducts.first(where: { $0.productId == self.productId }) {
                                    self.price = (Float(selectedProduct.price) / 100)
                                }
                            }
                        }.pickerStyle(.automatic)
                    }
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    HStack {
                        TextField("Price", value: $price, formatter: numberFormatter)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .padding(20)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2))
                            .frame(height: 100)
                    }
                }
                .padding().textFieldStyle(.roundedBorder)
                Button(action: {
                    Task(priority: .high) {
                        let postData: JobProductAddDTO = .init(
                            jobId: self.jobId,
                            productId: self.productId,
                            price: Int(self.price * 100)
                        )

                        print("pre-flight postData: \(postData)")

                        self.showProgress = true
                        try? await self.jobProductFetcher.postJobProductCreate(jobProduct: postData)
                        print("jobProductFetcher createResponse on view: \(jobProductFetcher.createResponse)")
                        self.showProgress = false
                        self.showCreateSuccess = jobProductFetcher.createResponse
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Product Added", isPresented: $showCreateSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                if !self.didAppear {
                    self.didAppear = true
                    Task {
                        let fetcher = CustomerProductManager(customerId: self.customerId)
                        self.showProgress = true
                        try? await fetcher.fetchData()
                        self.customerProducts = fetcher.customerProductData
                        if let selectedProduct = self.customerProducts.first(where: { $0.productId == self.productId }) {
                            self.price = (Float(selectedProduct.price) / 100)
                        }
                        self.showProgress = false
                    }
                }
            }
            .task {
                let fetcher = CustomerProductManager(customerId: self.customerId)
                try? await fetcher.fetchData()
                self.customerProducts = fetcher.customerProductData
            }
            .navigationTitle("Add Product")
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
}
