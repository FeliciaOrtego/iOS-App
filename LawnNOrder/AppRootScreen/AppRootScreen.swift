//
//  AppRootScreen.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 08/03/21.
//

import SwiftUI

struct AppRootScreen: View {
    let authManager: AuthManager
    @ObservedObject var customerManager: CustomerManager
    @ObservedObject var teamFetcher: TeamManager
    @ObservedObject var jobFetcher: JobManager
    @ObservedObject var productFetcher: ProductManager
    @ObservedObject var invoiceFetcher: InvoiceManager

    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    @ObservedObject var store: GWSPersistentStore
    var appConfig: GWSConfigurationProtocol
    @ObservedObject private var viewModel: AppRootScreenViewModel

    init(store: GWSPersistentStore, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.appConfig = appConfig
        viewModel = AppRootScreenViewModel(store: store, appConfig: appConfig)
        authManager = AuthManager.shared
        customerManager = CustomerManager.shared
        invoiceFetcher = InvoiceManager.shared
        jobFetcher = JobManager.shared
        teamFetcher = TeamManager.shared
        productFetcher = ProductManager.shared
    }

    @State private var selection = 0

    var landingScreenView: some View {
        GWSLandingScreenView(store: store,
                             appRootScreenViewModel: self.viewModel,
                             appConfig: appConfig,
                             welcomeTitle: "Welcome to Lawn and Order".localizedFeed,
                             welcomeDescription: "Use this application for creating teams, onboarding customers, scheduling jobs, and invoicing.".localizedFeed,
                             authManager: authManager)
    }

    var body: some View {
        Group {
            if !store.isWalkthroughCompleted() {
                GWSWalkthoughView(store: store, walkthroughData: appConfig.walkthroughData, appConfig: appConfig)
            } else if store.userIfLoggedInUser() != nil {
                if viewModel.resyncSuccess &&
                    self.authManager.isAdmin == true
                {
                    TabView(selection: $selection) {
                        JobsView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                            .tabItem {
                                Label("Jobs", systemImage: "hammer")
                            }.tag(0)
                        CustomersView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                            .tabItem {
                                Label("Customers", systemImage: "person")
                            }.tag(1)
                        InvoicesView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                            .tabItem {
                                Label("Invoices", systemImage: "doc")
                            }.tag(2)
                        ProductsView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                            .tabItem {
                                Label("Products", systemImage: "leaf")
                            }.tag(3)
                        TeamsView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                            .tabItem {
                                Label("Teams", systemImage: "person.2.fill")
                            }.tag(4)
                        ReportsView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                            .tabItem {
                                Label("Reports", systemImage: "chart.bar.doc.horizontal")
                            }.tag(5)
                        GWSProfileView(store: store, loggedInUser: viewModel.viewer, viewer: viewModel.viewer, hideNavigationBar: false, appConfig: appConfig)
                            .tabItem {
                                GWSProfileTabItem(appConfig: appConfig)
                            }.tag(6)
                        SettingsView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                            .tabItem {
                                Label("App Settings", systemImage:
                                    "gearshape")
                            }.tag(7)
                        /* GWSConversationsView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                         .tabItem {
                             GWSConversationsTabItem(appConfig: appConfig)
                         }.tag(7) */
                    }
                    .navigationViewStyle(.stack)
                } else if viewModel.resyncSuccess && self.authManager.isAdmin == false {
                    TabView(selection: $selection) {
                        JobsView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                            .tabItem {
                                Label("Jobs", systemImage: "hammer")
                            }.tag(0)
                        GWSProfileView(store: store, loggedInUser: viewModel.viewer, viewer: viewModel.viewer, hideNavigationBar: false, appConfig: appConfig)
                            .tabItem {
                                GWSProfileTabItem(appConfig: appConfig)
                            }.tag(1)
                        /* GWSConversationsView(store: store, viewer: viewModel.viewer, appConfig: appConfig)
                         .tabItem {
                             GWSConversationsTabItem(appConfig: appConfig)
                         }.tag(2) */
                    }
                } else if viewModel.resyncCompleted {
                    landingScreenView
                }
            } else {
                landingScreenView
            }
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showProgress ? 1 : 0)
        )
        .task {
            self.viewModel.resyncPersistentCredentials()
        }
        .onAppear {
            if !self.didAppear {
                self.didAppear = true
                Task {
                    print("getting all on app root appear")
                    self.showProgress = true
                    try? await self.teamFetcher.fetchData()
                    try? await self.customerManager.fetchData()
                    try? await self.invoiceFetcher.fetchData()
                    try? await self.jobFetcher.fetchData()
                    try? await self.teamFetcher.fetchData()
                    try? await self.productFetcher.fetchData()
                    self.showProgress = false
                }
            }
        }
        .task {
            print("getting all on app root view task")
            try? await self.teamFetcher.fetchData()
            try? await self.customerManager.fetchData()
            try? await self.invoiceFetcher.fetchData()
            try? await self.jobFetcher.fetchData()
            try? await self.teamFetcher.fetchData()
            try? await self.productFetcher.fetchData()
        }
    }
}

struct GWSConversationsTabItem: View {
    var appConfig: GWSConfigurationProtocol

    var body: some View {
        Text("Chat")
        Image("chat-filled")
            .configTabItemImage(isSelected: true, appConfig: appConfig)
    }
}

struct GWSFriendsTabItem: View {
    var appConfig: GWSConfigurationProtocol

    var body: some View {
        Text("Teams")
        Image("friends-filled")
            .configTabItemImage(isSelected: true, appConfig: appConfig)
    }
}

struct GWSProfileTabItem: View {
    var appConfig: GWSConfigurationProtocol

    var body: some View {
        Text("Profile")
        Image("profile-filled")
            .configTabItemImage(isSelected: true, appConfig: appConfig)
    }
}

extension Image {
    func configTabItemImage(isSelected: Bool, appConfig: GWSConfigurationProtocol) -> some View {
        if isSelected {
            return renderingMode(.template)
                .foregroundColor(Color(appConfig.mainThemeForegroundColor))
        } else {
            return renderingMode(.template)
                .foregroundColor(Color(appConfig.mainTextColor))
        }
    }
}
