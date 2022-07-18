//
//  CustomerAddView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/23/22.
//

// https://developer.apple.com/documentation/swiftui/form
// https://developer.apple.com/documentation/swiftui/textfield

import SwiftUI

struct CustomerAddView: View {
    @ObservedObject var customerFetcher: CustomerManager
    @Environment(\.presentationMode) var presentationMode

    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    @State private var selectedState: String = "IL"
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var address1: String = ""
    @State private var address2: String = ""
    @State private var city: String = ""
    @State private var zip: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""

    @State private var createSuccess: Bool = false

    init() {
        customerFetcher = CustomerManager.shared
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
                        let postData: CustomerDTO = .init(
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

                        print("pre-flight postData: \(postData)")

                        self.showProgress = true
                        try? await customerFetcher.postCustomerCreate(customer: postData)
                        self.showProgress = false
                        print("response on view: \(customerFetcher.createResponse)")
                        self.createSuccess = customerFetcher.createResponse
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Customer Added", isPresented: $createSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Add Customer")
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

struct SubmitButtonContent: View {
    var body: some View {
        return Text("SUBMIT".localizedCore)
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
}
