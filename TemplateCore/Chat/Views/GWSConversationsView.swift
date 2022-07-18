//
//  GWSConversationsView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 24/04/21.
//

import SwiftUI

struct GWSConversationsView: View {
    @ObservedObject var store: GWSPersistentStore
    var viewer: GWSUser?
    @ObservedObject private var viewModel: GWSConversationsViewModel
    var appConfig: GWSConfigurationProtocol

    init(store: GWSPersistentStore, viewer: GWSUser?, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        viewModel = GWSConversationsViewModel(user: viewer)
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    if !viewModel.showLoader {
                        if viewModel.channels.count == 0 {
                            GWSEmptyView(title: "No Conversations".localizedChat, subTitle: "Start chatting with the people you follow. Your conversations will show up here.".localizedChat, buttonTitle: "Find Friends".localizedChat, appConfig: appConfig, completionHandler: {})
                                .padding(.top, 50)
                        }
                        LazyVStack {
                            ForEach(viewModel.channels) { channel in
                                GWSConversationView(channel: channel, viewer: viewer, appConfig: appConfig)
                            }
                        }
                    }
                    Spacer()
                }.id(viewModel.updatingTime)
            }
            .overlay(
                VStack {
                    CPKProgressHUDSwiftUI()
                }
                .frame(width: 100,
                       height: 100)
                .opacity(viewModel.showLoader ? 1 : 0)
            )
            .navigationBarTitle("Messages".localizedCore, displayMode: .inline)
            .navigationBarItems(trailing:
                NavigationLink(destination: GWSChatGroupMembersView(viewer: viewer, appConfig: appConfig)) {
                    Image("inscription")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color(appConfig.mainTextColor))
                }
            )
        }
    }
}
