//
//  GWSProfileSettings.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 12/05/21.
//

import SwiftUI

enum GWSProfileSettingsType {
    case accountDetails
    case blockedUsers
    case settings
    case contactUs
    case none
}

struct GWSProfileSettings: View {
    @ObservedObject var viewModel: GWSProfileViewModel
    @ObservedObject var store: GWSPersistentStore
    @State var isNavigationActive: Bool?
    @State var profileSettings: GWSProfileSettingsType = .none
    var appConfig: GWSConfigurationProtocol
    var title: String

    let authManager: AuthManager = .init()

    init(viewModel: GWSProfileViewModel, store: GWSPersistentStore, appConfig: GWSConfigurationProtocol, title: String = "General".localizedFeed, clearBackground: Bool = false) {
        self.viewModel = viewModel
        self.store = store
        self.appConfig = appConfig
        self.title = title
        if clearBackground {
            UITableView.appearance().backgroundColor = .clear
        }
    }

    var body: some View {
        Form {
            Section(header: Text(title)) {
                Button(action: {
                    isNavigationActive = true
                    profileSettings = .accountDetails
                }) {
                    HStack {
                        Spacer()
                        Text("Account Details".localizedFeed)
                        Spacer()
                    }
                }
                Button(action: {
                    isNavigationActive = true
                    profileSettings = .blockedUsers
                }) {
                    HStack {
                        Spacer()
                        Text("Blocked Users".localizedFeed)
                        Spacer()
                    }
                }
                Button(action: {
                    isNavigationActive = true
                    profileSettings = .settings
                }) {
                    HStack {
                        Spacer()
                        Text("Settings".localizedFeed)
                        Spacer()
                    }
                }
                Button(action: {
                    isNavigationActive = true
                    profileSettings = .contactUs
                }) {
                    HStack {
                        Spacer()
                        Text("Contact Us".localizedCore)
                        Spacer()
                    }
                }
                Button(action: {
                    self.store.logout()
                    self.authManager.logOut()
                }) {
                    HStack {
                        Spacer()
                        Text("Log Out".localizedFeed)
                        Spacer()
                    }
                }
            }
        }.navigationBarTitle("Profile Settings".localizedFeed)
            .navigate(using: $isNavigationActive, destination: makeDestination)
    }

    @ViewBuilder
    private func makeDestination(for _: Bool) -> some View {
        switch profileSettings {
        case .accountDetails:
            GWSEditProfileView(viewModel: viewModel)
        case .blockedUsers:
            GWSBlockedUsersView(loggedInUser: viewModel.loggedInUser, appConfig: appConfig)
        case .settings:
            GWSUserSettings(viewModel: viewModel)
        case .contactUs:
            GWSContactUsView()
        case .none:
            EmptyView()
        }
    }
}
