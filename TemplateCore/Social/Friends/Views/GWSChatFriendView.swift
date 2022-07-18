//
//  GWSChatFriendView.swift
//  ChatApp
//
//  Created by Jared Sullivan and Mayil Kannan on 22/07/21.
//

import SwiftUI

struct GWSChatFriendView: View {
    var friendship: GWSChatFriendship?
    var viewer: GWSUser?
    var user: GWSUser
    @ObservedObject var viewModel: GWSChatFriendsViewModel
    var appConfig: GWSConfigurationProtocol

    var followerActionText: String {
        guard let friendship = friendship else {
            return "Add"
        }
        switch friendship.type {
        case .inbound:
            return "Accept".localizedChat
        case .outbound:
            return"Cancel".localizedCore
        case .mutual:
            return ""
        }
    }

    var body: some View {
        HStack(alignment: VerticalAlignment.center) {
            if let profilePictureURL = user.profilePictureURL, !profilePictureURL.isEmpty {
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
            Text(user.fullName())
                .foregroundColor(Color(appConfig.mainTextColor))
                .font(.system(size: 15, weight: .medium))
            Spacer()
            if !followerActionText.isEmpty {
                Button(action: {
                    guard let friendship = friendship else {
                        self.viewModel.addFriendRequest(fromUser: viewer, toUser: user)
                        return
                    }
                    switch friendship.type {
                    case .inbound:
                        // Accept friendship
                        self.viewModel.acceptFriendRequest(fromUser: friendship.otherUser,
                                                           toUser: friendship.currentUser)
                    case .outbound:
                        // Cancel friend request
                        self.viewModel.cancelFriendRequest(fromUser: friendship.currentUser,
                                                           toUser: friendship.otherUser)
                    default: break
                    }
                    viewModel.followTextUpdatingTime = Date()
                }) {
                    Text(followerActionText)
                        .font(.system(size: 15))
                        .frame(width: 100)
                        .frame(height: 35)
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                        .foregroundColor(Color.white)
                        .background(Color(appConfig.mainThemeForegroundColor))
                        .cornerRadius(6)
                        .id(viewModel.followTextUpdatingTime)
                }.padding(.trailing, 20)
            }
        }
        .frame(height: 50)
    }
}
