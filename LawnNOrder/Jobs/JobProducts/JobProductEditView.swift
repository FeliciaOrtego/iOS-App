//
//  JobProductsDetailView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 4/10/22.
//

import SwiftUI

struct JobProductEditView: View {
    let jobProduct: ProductViewModel
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var jobProductFetcher: JobProductManager

    private let numberFormatter: NumberFormatter

    @State private var name: String = ""
    @State private var price: Float = 0
    @State private var updateSuccess: Bool = false
    @State private var deleteSuccess: Bool = false
    @State private var updateFailed: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    init(jobProduct: ProductViewModel) {
        self.jobProduct = jobProduct
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        _name = State(initialValue: self.jobProduct.name)
        _price = State(initialValue: Float(self.jobProduct.price) / 100)
        jobProductFetcher = JobProductManager(jobId: self.jobProduct.jobId ?? -1)
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

                        let putData: ProductViewModel = .init(
                            id: self.jobProduct.id,
                            jobId: self.jobProduct.jobId,
                            productId: self.jobProduct.productId,
                            name: self.name,
                            price: Int(self.price * 100)
                        )

                        print("pre-flight putData: \(putData)")

                        try? await jobProductFetcher.putProductUpdate(jobProduct: putData)
                        print("jobProductFetcher updateSuccess on view: \(jobProductFetcher.updateResponse)")
                        self.showProgress = false
                        self.updateSuccess = jobProductFetcher.updateResponse
                        self.updateFailed = jobProductFetcher.updateFailed
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
                        try? await jobProductFetcher.deleteProduct(jobProductId: jobProduct.id)
                        print("jobProductFetcher deleteProduct on view: \(jobProductFetcher.deleteResponse)")
                        self.showProgress = false
                        self.deleteSuccess = jobProductFetcher.deleteResponse
                    }
                }) {
                    DeleteButtonContent()
                }
                .alert("Product Deleted", isPresented: $deleteSuccess) {
                    Button("OK", role: .destructive) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                .alert("Update failed please correct form".localizedCore, isPresented: $updateFailed) {
                    Button("OK", role: .destructive) {}
                }
                .padding()
                Spacer()
            }
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
