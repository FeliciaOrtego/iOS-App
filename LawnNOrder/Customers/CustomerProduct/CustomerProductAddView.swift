//
//  CustomerProductAddView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/23/22.
//

// https://developer.apple.com/documentation/swiftui/form
// https://developer.apple.com/documentation/swiftui/textfield

import SwiftUI

struct CustomerProductAddView: View {
    @ObservedObject private var productFetcher: ProductManager
    @ObservedObject private var customerProductFetcher: CustomerProductManager
    @Environment(\.presentationMode) var presentationMode

    let customerId: Int

    @State private var createSuccess: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    @State private var productId: Int = -1
    @State private var price: Float = 0

    private var numberFormatter: NumberFormatter

    init(customerId: Int) {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        self.customerId = customerId
        productFetcher = ProductManager.shared
        customerProductFetcher = CustomerProductManager(customerId: customerId)
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    Picker("Product", selection: $productId) {
                        ForEach(productFetcher.productData) { product in
                            Text(product.name)
                                .tag(product.id)
                        }
                    }.onChange(of: self.productId) {
                        _ in print("Selected Product Id : \(String(self.productId))")
                        print("getting default price on Product change")
                        if let selectedProduct = productFetcher.productData.first(where: { $0.id == self.productId }) {
                            self.price = (Float(selectedProduct.price) / 100)
                        }
                    }.pickerStyle(DefaultPickerStyle.automatic)
                    VStack {
                        TextField("$0.00", value: $price, formatter: numberFormatter)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .padding(20)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2))
                            .frame(height: 100)

                        Rectangle()
                            .frame(width: 0, height: 40)
                    }
                    .padding().textFieldStyle(.roundedBorder)
                }
                Button(action: {
                    Task(priority: .high) {
                        let postData: CustomerProductAddDTO = .init(
                            customerId: customerId,
                            productId: productId,
                            price: Int(self.price * 100)
                        )

                        print("pre-flight postData: \(postData)")

                        self.showProgress = true
                        try? await self.customerProductFetcher.postCustomerProductCreate(customerProduct: postData)
                        self.showProgress = false
                        self.createSuccess = self.customerProductFetcher.createResponse
                        print("customer product createSuccess: \(self.createSuccess)")
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Product Added", isPresented: $createSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding()
                Spacer()
            }
            .padding().textFieldStyle(.roundedBorder)
            .navigationTitle("Add Product")
            .onAppear {
                if !self.didAppear {
                    self.didAppear = true
                    Task {
                        try? await self.productFetcher.fetchData()
                    }
                }
            }
            .task {
                try? await self.productFetcher.fetchData()
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
