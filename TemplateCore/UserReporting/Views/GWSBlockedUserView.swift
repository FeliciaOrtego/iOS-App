//
//  GWSBlockedUserView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 30/05/21.
//

import SwiftUI

struct GWSBlockedUserView: View {
    @ObservedObject var viewModel: GWSBlockedUserViewModel
    var blockedUser: GWSUser
    var appConfig: GWSConfigurationProtocol

    var body: some View {
        VStack {
            HStack(alignment: VerticalAlignment.center) {
                if let profilePictureURL = blockedUser.profilePictureURL, !profilePictureURL.isEmpty {
                    GWSNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                    placeholderImage: UIImage(named: "empty-avatar")!)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 50, height: 50)
                        .padding(.leading, 4)
                } else {
                    Image("empty-avatar")
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 50, height: 50)
                        .padding(.leading, 4)
                }
                VStack {
                    Text(blockedUser.fullName())
                        .foregroundColor(Color(appConfig.mainTextColor))
                    Text(blockedUser.email ?? "")
                        .foregroundColor(Color(appConfig.mainTextColor))
                }
                Spacer()
                Button(action: {
                    viewModel.unBlockUser(unBlockUser: blockedUser)
                }) {
                    Text("unblock".localizedFeed)
                        .frame(width: 100)
                        .frame(height: 35)
                        .contentShape(Rectangle())
                        .foregroundColor(Color(appConfig.mainThemeForegroundColor))
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
            .padding(20)
        }
        .frame(height: 100)
        .background(
            Color.white
                .cornerRadius(10)
                .shadow(radius: 10)
        )
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
    }
}
