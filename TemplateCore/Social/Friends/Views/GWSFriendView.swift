//
//  GWSFriendView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 19/04/21.
//

import SwiftUI

struct GWSFriendView: View {
    var viewer: GWSUser?
    var user: GWSUser
    @ObservedObject var viewModel: GWSFriendsViewModel
    var appConfig: GWSConfigurationProtocol

    var followerActionText: String {
        if viewModel.isFollowersFollowingEnabled && viewer?.uid != viewModel.loggedInUser?.uid {
            if viewModel.loggedInOutBoundUsers.contains(user) {
                return "Unfollow".localizedChat
            } else if viewModel.loggedInInBoundUsers.contains(user) {
                return "Follow Back".localizedChat
            } else {
                return "Follow".localizedChat
            }
        } else {
            if viewModel.outBoundUsers.contains(user) {
                return "Unfollow".localizedChat
            } else if viewModel.filteredInBoundUsers.contains(user) {
                return "Follow Back".localizedChat
            } else {
                return "Follow".localizedChat
            }
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
            Button(action: {
                if viewModel.isFollowersFollowingEnabled, viewer?.uid != viewModel.loggedInUser?.uid {
                    if followerActionText == "Unfollow".localizedChat {
                        if let outBoundUserIndex = viewModel.loggedInOutBoundUsers.firstIndex(of: user) {
                            viewModel.removeFriendRequest(fromUser: viewModel.loggedInUser, toUser: user)
                            viewModel.loggedInOutBoundUsers.remove(at: outBoundUserIndex)
                        }
                    } else {
                        viewModel.loggedInOutBoundUsers.append(user)
                        viewModel.addFriendRequest(fromUser: viewModel.loggedInUser, toUser: user)
                    }
                    viewModel.followTextUpdatingTime = Date()
                } else {
                    if followerActionText == "Unfollow".localizedChat, !viewModel.isFollowersFollowingEnabled || (viewModel.isFollowersFollowingEnabled && !viewModel.showFollowers) {
                        if let outBoundUserIndex = viewModel.outBoundUsers.firstIndex(of: user) {
                            viewModel.outBoundUsers.remove(at: outBoundUserIndex)
                            viewModel.removeFriendRequest(fromUser: viewer, toUser: user)
                            if viewModel.allInBoundUsers.contains(user) {
                                viewModel.filteredInBoundUsers.append(user)
                            }
                        }
                    } else {
                        if followerActionText == "Follow Back".localizedChat {
                            if let filteredInBoundUserIndex = viewModel.filteredInBoundUsers.firstIndex(of: user) {
                                viewModel.filteredInBoundUsers.remove(at: filteredInBoundUserIndex)
                            }
                        }
                        if !viewModel.outBoundUsers.contains(user) {
                            viewModel.outBoundUsers.append(user)
                            viewModel.addFriendRequest(fromUser: viewer, toUser: user)
                        }
                    }
                }
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
        .frame(height: 50)
    }
}
