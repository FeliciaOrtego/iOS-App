//
//  ProductEditView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/23/22.
//

import SwiftUI

struct ProductEditView: View {
    let product: ProductViewModel
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var productFetcher: ProductManager
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    @State private var name: String = ""
    @State private var price: Float = 0
    @State private var updateSuccess: Bool = false
    @State private var deleteSuccess: Bool = false

    private let numberFormatter: NumberFormatter

    init(product: ProductViewModel) {
        self.product = product
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        _name = State(initialValue: product.name)
        _price = State(initialValue: Float(product.price) / 100)
        productFetcher = ProductManager.shared
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    TextField("Name", text: $name)
                        .disableAutocorrection(true)
                        .border(.secondary)
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
                        print("pre-flight self.price: \(self.price)")

                        let putData: ProductEditDTO = .init(
                            id: product.id,
                            name: self.name,
                            price: Int(self.price * 100)
                        )

                        print("pre-flight putData: \(putData)")

                        self.showProgress = true
                        try? await productFetcher.putProductUpdate(product: putData)
                        self.showProgress = false

                        print("productFetcher putProductUpdate on view: \(productFetcher.updateResponse)")
                        self.updateSuccess = productFetcher.updateResponse
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Product Updated", isPresented: $updateSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                Button(action: {
                    Task(priority: .high) {
                        self.showProgress = true
                        try? await productFetcher.deleteProduct(productId: product.id)
                        self.showProgress = false
                        print("productFetcher deleteProduct on view: \(productFetcher.deleteResponse)")
                        self.deleteSuccess = productFetcher.deleteResponse
                    }
                }) {
                    DeleteButtonContent()
                }
                .alert("Product Deleted", isPresented: $deleteSuccess) {
                    Button("OK", role: .destructive) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                Spacer()
            }
        }
    }
}
