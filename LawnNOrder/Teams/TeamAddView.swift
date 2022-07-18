//
//  TeamAddView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/18/22.
//

import SwiftUI

struct TeamAddView: View {
    @ObservedObject var teamFetcher: TeamManager
    @ObservedObject var userFetcher: UserManager

    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var leadUserId: Int = -1

    @State private var showCreateSuccess: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    init() {
        userFetcher = UserManager.shared
        teamFetcher = TeamManager.shared
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    Text("Name")
                    TextField("Name", text: $name)
                        .disableAutocorrection(true)
                        .border(.secondary)
                }
                .padding().textFieldStyle(.roundedBorder)
                VStack {
                    Text("Lead")
                    Picker("Lead", selection: $leadUserId) {
                        ForEach(userFetcher.userData) { user in
                            Text(user.name)
                                .tag(user.id)
                        }
                    }.pickerStyle(WheelPickerStyle.wheel)
                }
                .padding().textFieldStyle(.roundedBorder)
                Button(action: {
                    Task(priority: .high) {
                        let postData: TeamDTO = .init(
                            name: self.name,
                            leadUserId: self.leadUserId
                        )

                        print("pre-flight postData: \(postData)")

                        self.showProgress = true
                        try? await teamFetcher.postTeamCreate(team: postData)
                        self.showProgress = false

                        print("response on view: \(teamFetcher.createResponse)")
                        self.showCreateSuccess = teamFetcher.createResponse
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Team Added", isPresented: $showCreateSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                Spacer()
            }
        }
        .navigationTitle("Add Team")
        .task {
            try? await self.userFetcher.fetchData()
        }
        .onAppear {
            if !self.didAppear {
                self.didAppear = true
                Task {
                    self.showProgress = true
                    try? await self.userFetcher.fetchData()
                    self.showProgress = false
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
    }
}
