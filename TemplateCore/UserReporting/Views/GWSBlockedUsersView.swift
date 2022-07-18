//
//  GWSBlockedUsersView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 30/05/21.
//

import SwiftUI

struct GWSBlockedUsersView: View {
    @ObservedObject var viewModel: GWSBlockedUserViewModel
    var appConfig: GWSConfigurationProtocol

    init(loggedInUser: GWSUser?, appConfig: GWSConfigurationProtocol) {
        viewModel = GWSBlockedUserViewModel(loggedInUser: loggedInUser)
        self.appConfig = appConfig
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                if !viewModel.isBlockedUsersFetching {
                    if viewModel.blockedUsers.count == 0 {
                        GWSEmptyView(title: "No Blocked Users".localizedFeed, subTitle: "You haven't blocked nor reported anyone yet. The users that you block or report will show up here.".localizedFeed, buttonTitle: "", hideButton: true, appConfig: appConfig)
                            .padding(.top, 50)
                    }
                    LazyVStack {
                        ForEach(viewModel.blockedUsers, id: \.self) { user in
                            GWSBlockedUserView(viewModel: viewModel, blockedUser: user, appConfig: appConfig)
                        }
                    }
                }
                Spacer()
            }
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.isBlockedUsersFetching ? 1 : 0)
        )
        .onAppear {
            if !self.viewModel.isBlockedUsersFetching {
                self.viewModel.fetchBlockedUsers()
            }
        }
        .navigationBarTitle("Blocked Users".localizedFeed, displayMode: .inline)
    }
}
