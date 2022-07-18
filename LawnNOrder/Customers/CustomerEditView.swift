//
//  CustomerEditView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/18/22.
//

import SwiftUI

struct CustomerEditView: View {
    let customer: CustomerViewModel
    let customerDTO: CustomerDTO = .defaultCustomer
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var customerFetcher: CustomerManager
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    @State private var selectedState: String = "AK"
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var address1: String = ""
    @State private var address2: String = ""
    @State private var city: String = ""
    @State private var zip: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""

    @State private var updateSuccess: Bool = false

    init(customer: CustomerViewModel) {
        self.customer = customer
        customerFetcher = CustomerManager.shared
        _selectedState = State(initialValue: customer.state)
        _firstName = State(initialValue: customer.firstName)
        _lastName = State(initialValue: customer.lastName)
        _address1 = State(initialValue: customer.address1)
        _address2 = State(initialValue: customer.address2)
        _city = State(initialValue: customer.city)
        _zip = State(initialValue: customer.zip)
        _phone = State(initialValue: customer.phone)
        _email = State(initialValue: customer.email)
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    TextField("First Name", text: $firstName)
                        .disableAutocorrection(true)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    TextField("Last Name", text: $lastName)
                        .disableAutocorrection(true)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    TextField("Address", text: $address1)
                        .disableAutocorrection(true)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    TextField("Address2", text: $address2)
                        .disableAutocorrection(true)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    TextField("City", text: $city)
                        .disableAutocorrection(true)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    TextField("Zip", text: $zip)
                        .disableAutocorrection(true)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    Picker("State", selection: $selectedState) {
                        ForEach(StateList.allCases) { state in
                            Text(state.rawValue)
                                .tag(state.rawValue)
                        }
                    }.pickerStyle(.automatic)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    TextField("Phone", text: $phone)
                        .disableAutocorrection(true)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    TextField("Email", text: $email)
                        .autocapitalization(UITextAutocapitalizationType.none)
                        .disableAutocorrection(true)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
                Button(action: {
                    Task(priority: .high) {
                        let putData: CustomerEditDTO = .init(
                            id: customer.id,
                            companyId: 1,
                            firstName: self.firstName,
                            lastName: self.lastName,
                            address1: self.address1,
                            address2: self.address2,
                            city: self.city,
                            state: selectedState,
                            zip: self.zip,
                            phone: self.phone,
                            email: self.email
                        )

                        print("pre-flight putData: \(putData)")

                        self.showProgress = true
                        try? await customerFetcher.putCustomerUpdate(customer: putData)
                        self.showProgress = false
                        print("customerFetcher updateResponse on view: \(customerFetcher.updateResponse)")
                        self.updateSuccess = customerFetcher.updateResponse
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Customer Updated", isPresented: $updateSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Edit Customer")
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

struct DeleteButtonContent: View {
    var body: some View {
        return Text("DELETE")
            .frame(minWidth: 0, maxWidth: 120)
            .frame(height: 35)
            .foregroundColor(Color.white)
            .background(Color.red)
            .cornerRadius(45 / 2)
            .padding(.horizontal, 30)
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.sRGB, red: 150 / 255, green: 150 / 255, blue: 150 / 255, opacity: 0.2), lineWidth: 1)
            )
    }
}
