//
//  CustomerDetail.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/20/22.
//

import SwiftUI

struct CustomerDetailView: View {
    let customer: CustomerViewModel

    @ObservedObject var customerFetcher: CustomerManager
    @Environment(\.openURL) var openURL

    @State private var customerProducts = [ProductViewModel]()

    @Environment(\.presentationMode) var presentationMode

    @State private var deleteSuccess: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    private let numberFormatter: NumberFormatter
    @State private var changedAddress: String?

    init(customer: CustomerViewModel) {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        self.customer = customer
        customerFetcher = CustomerManager.shared
    }

    func openMap(Address: String) {
        changedAddress = Address.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: "http://maps.apple.com/?address=\(changedAddress!)") else {
            return
        }
        openURL(url)
    }

    var body: some View {
        Text(customer.displayName)
            .font(.system(size: 22))

        VStack(alignment: .center) {
            Button(action: {
                openMap(Address: customer.displayAddress)
            }) {
                Text(customer.displayAddress)
            }.font(.system(size: 22, weight: .bold))
                .padding()
            Link(customer.email, destination: URL(string: "tel:" + customer.phone)!)
                .padding()
            Link(customer.phone, destination: URL(string: "mailto:" + customer.email)!)
                .padding()
            List(self.customerProducts) { product in
                NavigationLink {
                    CustomerProductEditView(customerProduct: product, customerId: self.customer.id)
                }
                        label: {
                    Text(product.name)
                    Text(self.numberFormatter.string(from: Float(product.price) / 100 as NSNumber) ?? "0.00")
                        .font(.system(size: 14, weight: .light))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }.refreshable {
                let fetcher = CustomerProductManager(customerId: self.customer.id)
                try? await fetcher.fetchData()
                self.customerProducts = fetcher.customerProductData
            }
            NavigationLink {
                CustomerProductAddView(customerId: customer.id)
            }
                    label: {
                Text("Add Product".localizedCore)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 45)
                    .foregroundColor(Color.white)
                    .background(Color(UIColor(hexString: "#008000")))
                    .cornerRadius(45 / 2)
                    .padding(.horizontal, 50)
                    .padding(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.sRGB, red: 150 / 255, green: 150 / 255, blue: 150 / 255, opacity: 0.2), lineWidth: 1)
                    )
            }
            Spacer()
            Button(action: {
                Task(priority: .high) {
                    self.showProgress = true
                    try? await customerFetcher.deleteCustomer(customerId: customer.id)
                    self.showProgress = false
                    print("customerFetcher deleteResponse on view: \(customerFetcher.deleteResponse)")
                    self.deleteSuccess = customerFetcher.deleteResponse
                }
            }) {
                DeleteButtonContent()
            }
            .alert("Customer Deleted", isPresented: $deleteSuccess) {
                Button("OK", role: .destructive) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .layoutPriority(100)
        .cornerRadius(10)
        .padding([.top, .horizontal])
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.sRGB, red: 150 / 255, green: 150 / 255, blue: 150 / 255, opacity: 0.1), lineWidth: 1)
        )
        .toolbar {
            HStack {
                if self.customerProducts.count > 0 {
                    NavigationLink {
                        JobAddView(customerId: customer.id, customer: customer,
                                   isSchedule: true, isInvoiceInitialJob: false, invoiceId: -1)
                    }
                        label: {
                        Text("Add Job")
                    }
                }

                NavigationLink {
                    CustomerEditView(customer: customer)
                }
                    label: {
                    Text("Edit")
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
        .onAppear {
            if !self.didAppear {
                self.didAppear = true
                Task {
                    let fetcher = CustomerProductManager(customerId: self.customer.id)
                    try? await fetcher.fetchData()
                    self.customerProducts = fetcher.customerProductData
                }
            }
        }
        .task {
            let fetcher = CustomerProductManager(customerId: self.customer.id)
            try? await fetcher.fetchData()
            self.customerProducts = fetcher.customerProductData
        }
    }
}
