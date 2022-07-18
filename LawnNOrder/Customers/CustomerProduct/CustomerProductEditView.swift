//
//  CustomerProductEditView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/23/22.
//

// https://developer.apple.com/documentation/swiftui/form
// https://developer.apple.com/documentation/swiftui/textfield

import SwiftUI

struct CustomerProductEditView: View {
    @Environment(\.presentationMode) var presentationMode

    let customerProduct: ProductViewModel
    let customerId: Int

    @ObservedObject private var customerProductFetcher: CustomerProductManager

    @State private var price: Float = 0
    @State private var updateSuccess: Bool = false
    @State private var deleteSuccess: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    private var numberFormatter: NumberFormatter

    init(customerProduct: ProductViewModel, customerId: Int) {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        self.customerProduct = customerProduct
        self.customerId = customerId
        customerProductFetcher = CustomerProductManager(customerId: customerId)
        _price = State(initialValue: Float(customerProduct.price) / 100)
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    Text(customerProduct.name)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
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
                Button(action: {
                    Task(priority: .high) {
                        print("pre-flight price: \(self.price)")

                        let putData: ProductEditDTO = .init(
                            id: customerProduct.id,
                            name: customerProduct.name,
                            price: Int(self.price * 100)
                        )

                        print("pre-flight putData: \(putData)")

                        try? await self.customerProductFetcher.putCustomerProductUpdate(customerProduct: putData)
                        self.updateSuccess = self.customerProductFetcher.updateResponse
                        print("customer product updateSuccess: \(self.updateSuccess)")
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Product Updated".localizedCore, isPresented: $updateSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                Button(action: {
                    Task(priority: .high) {
                        self.showProgress = true
                        try? await self.customerProductFetcher.deleteCustomerProduct(customerProductId: customerProduct.id)
                        self.showProgress = false
                        self.deleteSuccess = self.customerProductFetcher.deleteResponse
                        print("customer product deleteSuccess: \(self.deleteSuccess)")
                    }
                }) {
                    DeleteButtonContent()
                }
                .alert("Product Deleted".localizedCore, isPresented: $deleteSuccess) {
                    Button("OK", role: .destructive) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding()
                Spacer()
            }
            .navigationTitle("Edit Product")
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
