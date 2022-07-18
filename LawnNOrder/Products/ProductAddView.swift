//
//  ProductAddView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/23/22.
//

// https://developer.apple.com/documentation/swiftui/form
// https://developer.apple.com/documentation/swiftui/textfield

import SwiftUI

struct ProductAddView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var productFetcher: ProductManager

    @State private var name: String = ""
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false
    @State private var price: Float = 0

    @State private var showCreateSuccess: Bool = false

    private let numberFormatter: NumberFormatter

    init() {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
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
                        let postData: ProductAddDTO = .init(
                            companyId: 1,
                            name: self.name,
                            price: Int(self.price * 100)
                        )

                        print("pre-flight postData: \(postData)")

                        self.showProgress = true
                        try? await self.productFetcher.postProductCreate(product: postData)
                        self.showProgress = false
                        self.showCreateSuccess = self.productFetcher.createResponse
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Product Added", isPresented: $showCreateSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                Spacer()
            }
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
