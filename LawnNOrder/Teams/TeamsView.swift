//
//  SettingsView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/20/22.
//

import SwiftUI

struct TeamsView: View {
    @ObservedObject var store: GWSPersistentStore
    @ObservedObject var teamFetcher: TeamManager

    var viewer: GWSUser?
    var appConfig: GWSConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    init(store: GWSPersistentStore, viewer: GWSUser?, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        teamFetcher = TeamManager.shared
    }

    var body: some View {
        NavigationView {
            List(teamFetcher.teamData) { team in
                NavigationLink {
                    TeamEditView(team: team)
                }
                label: {
                    TeamRowView(team: team)
                }
            }.refreshable {
                print("getting teams on view refresh")
                try? await self.teamFetcher.fetchData()
            }
            .toolbar {
                NavigationLink {
                    TeamAddView()
                }
                label: {
                    Text("Add")
                }
            }
            .navigationTitle("Teams")
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
                    print("getting teams on view appear")
                    try? await self.teamFetcher.fetchData()
                }
            }
        }
        .task {
            print("getting teams on view task")
            try? await self.teamFetcher.fetchData()
        }
        .navigationViewStyle(.stack)
    }
}
