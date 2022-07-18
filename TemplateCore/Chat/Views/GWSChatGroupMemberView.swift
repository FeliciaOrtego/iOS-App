//
//  GWSChatGroupMemberView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 19/04/21.
//

import SwiftUI

struct GWSChatGroupMemberView: View {
    var user: GWSUser
    @ObservedObject var viewModel: GWSChatGroupMembersViewModel
    @Binding var showCreateGroupOption: Double
    var appConfig: GWSConfigurationProtocol

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
            Spacer()
            if viewModel.selectedFriends.contains(user) {
                Image("checked")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.selectedFriends.contains(user) {
                viewModel.selectedFriends = viewModel.selectedFriends.filter { $0 != user }
            } else {
                viewModel.selectedFriends.append(user)
            }
            showCreateGroupOption = viewModel.selectedFriends.count > 1 ? 1 : 0
        }
        .frame(height: 50)
    }
}
