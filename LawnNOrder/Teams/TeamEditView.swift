//
//  TeamEditView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 2/18/22.
//

import SwiftUI

struct TeamEditView: View {
    let team: TeamViewModel
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var teamFetcher: TeamManager
    @ObservedObject var userFetcher: UserManager

    @State private var name: String = ""
    @State private var leadUserId: Int = -1

    @State private var updateSuccess: Bool = false
    @State private var deleteSuccess: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    init(team: TeamViewModel) {
        self.team = team
        _name = State(initialValue: team.name)
        _leadUserId = State(initialValue: team.leadUserId)
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
                        let putData: TeamEditDTO = .init(
                            id: self.team.id,
                            name: self.name,
                            leadUserId: self.leadUserId
                        )

                        print("pre-flight putData: \(putData)")

                        self.showProgress = true
                        try? await teamFetcher.putTeamUpdate(team: putData)
                        self.showProgress = false
                        print("teamFetcher putTeamUpdate on view: \(teamFetcher.updateResponse)")
                        self.updateSuccess = teamFetcher.updateResponse
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Team Updated", isPresented: $updateSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                Button(action: {
                    Task(priority: .high) {
                        self.showProgress = true
                        try? await teamFetcher.deleteTeam(teamId: team.id)
                        self.showProgress = false
                        print("teamFetcher deleteTeam on view: \(teamFetcher.deleteResponse)")
                        self.deleteSuccess = teamFetcher.deleteResponse
                    }
                }) {
                    DeleteButtonContent()
                }
                .alert("Team Deleted", isPresented: $deleteSuccess) {
                    Button("OK", role: .destructive) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                Spacer()
            }
        }
        .navigationTitle("Edit Team")
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
