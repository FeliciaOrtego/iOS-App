//
//  GWSUserSettings.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 15/05/21.
//

import SwiftUI

struct GWSUserSettings: View {
    @State var isPushNotificationsEnabled: Bool = false
    @State var isFaceIDOrTouchIDEnabled: Bool = false
    @ObservedObject var viewModel: GWSProfileViewModel

    init(viewModel: GWSProfileViewModel) {
        self.viewModel = viewModel
        _isFaceIDOrTouchIDEnabled = State(initialValue: viewModel.loggedInUser?.settings[self.viewModel.face_id_key] as? Bool ?? false)
        if self.viewModel.loggedInUser?.settings[self.viewModel.push_notification_key] == nil {
            _isPushNotificationsEnabled = State(initialValue: isPushNotificationEnabled)
        } else {
            _isPushNotificationsEnabled = State(initialValue: viewModel.loggedInUser?.settings[self.viewModel.push_notification_key] as? Bool ?? false)
        }
    }

    var body: some View {
        Form {
            Section(header: Text("GENERAL".localizedChat)) {
                HStack {
                    Toggle(isOn: $isPushNotificationsEnabled) {
                        Text("Allow Push Notifications".localizedChat)
                    }
                }
                HStack {
                    Toggle(isOn: $isFaceIDOrTouchIDEnabled) {
                        Text("Enable Face ID / Touch ID".localizedChat)
                    }
                }
            }
            Section(header: Text("")) {
                Button(action: {
                    self.viewModel.updateSettings(isPushNotificationsEnabled: isPushNotificationsEnabled,
                                                  isFaceIDOrTouchIDEnabled: isFaceIDOrTouchIDEnabled)
                }) {
                    HStack {
                        Spacer()
                        Text("Save".localizedCore)
                        Spacer()
                    }
                }
            }
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showLoader ? 1 : 0)
        ).navigationBarTitle("User Settings".localizedChat)
    }

    var isPushNotificationEnabled: Bool {
        var isRegisteredForRemoteNotifications = false

        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { permission in
            switch permission.authorizationStatus {
            case .authorized:
                isRegisteredForRemoteNotifications = true
            default:
                isRegisteredForRemoteNotifications = false
            }
        })

        return isRegisteredForRemoteNotifications
    }
}
