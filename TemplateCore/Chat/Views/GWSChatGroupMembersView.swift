//
//  GWSChatGroupMembersView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 20/05/21.
//

import SwiftUI

struct GWSChatGroupMembersView: View {
    var viewer: GWSUser?
    @ObservedObject private var viewModel: GWSChatGroupMembersViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var showCreateGroupOption: Double = 0
    var appConfig: GWSConfigurationProtocol

    init(viewer: GWSUser?, appConfig: GWSConfigurationProtocol, isChatApp: Bool = false) {
        self.viewer = viewer
        self.appConfig = appConfig
        viewModel = GWSChatGroupMembersViewModel(isChatApp: isChatApp)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                if !viewModel.showProgress {
                    if viewModel.groupMembers.count < 2 {
                        GWSEmptyView(title: "You can't create groups".localizedChat, subTitle: "You don't have enough friends to create groups. Add at least 2 friends to be able to create groups.".localizedChat, buttonTitle: "Go back".localizedChat, appConfig: appConfig) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        LazyVStack {
                            ForEach(viewModel.groupMembers, id: \.self) { user in
                                GWSChatGroupMemberView(user: user, viewModel: viewModel, showCreateGroupOption: $showCreateGroupOption, appConfig: appConfig)
                            }
                        }
                    }
                }
                Spacer()
            }.padding()
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showProgress ? 1 : 0)
        )
        .onAppear {
            self.viewModel.fetchFriends(viewer: viewer)
        }
        .navigationBarTitle("Choose People", displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: {
                self.viewModel.createChannel(creator: viewer) { _ in
                    self.presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text("Create")
            }.opacity(showCreateGroupOption)
        )
    }
}
