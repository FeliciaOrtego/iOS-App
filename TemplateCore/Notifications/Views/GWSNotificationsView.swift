//
//  GWSNotificationsView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 25/05/21.
//

import SwiftUI

struct GWSNotificationsView: View {
    var viewer: GWSUser?
    var appConfig: GWSConfigurationProtocol
    @ObservedObject private var viewModel = GWSNotificationsViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                if !viewModel.showLoader {
                    if viewModel.notifications.count == 0 {
                        GWSEmptyView(title: "No Notifications".localizedFeed, subTitle: "You currently do not have any notifications. Your notifications will show up here.".localizedFeed, buttonTitle: "", hideButton: true, appConfig: appConfig)
                            .padding(.top, 50)
                    }
                    LazyVStack {
                        ForEach(viewModel.notifications) { notification in
                            GWSNotificationView(notification: notification, appConfig: appConfig)
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
            .opacity(viewModel.showLoader ? 1 : 0)
        )
        .onAppear {
            self.viewModel.fetchNotifications(loggedInUser: viewer)
        }
        .navigationBarTitle("Notifications".localizedFeed, displayMode: .inline)
    }
}
