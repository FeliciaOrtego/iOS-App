//
//  GWSStoryView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 09/04/21.
//

import SwiftUI

struct GWSStoryView: View {
    var gridItemLayout = [GridItem(.flexible())]
    @Binding var storiesUserState: GWSCoreStoriesUserState
    let imageHeight: CGFloat = 58
    @Binding var isStoryContentPresented: Bool
    @Binding var selectedStories: [GWSStory]
    @Binding var showImagePickerOption: Bool
    @Binding var userStoriesIndex: Int
    @ObservedObject var feedViewModel: GWSFeedViewModel
    var appConfig: GWSConfigurationProtocol

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: gridItemLayout, spacing: 5) {
                if storiesUserState.selfStory == false, let user = feedViewModel.loggedInUser {
                    VStack(alignment: HorizontalAlignment.center) {
                        if let profilePictureURL = user.profilePictureURL, !profilePictureURL.isEmpty {
                            GWSNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                            placeholderImage: UIImage(named: "empty-avatar")!)
                                .aspectRatio(contentMode: .fill)
                                .clipShape(Circle())
                                .frame(width: imageHeight, height: imageHeight)
                        } else {
                            Image("empty-avatar")
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: imageHeight, height: imageHeight)
                        }
                        Text("Add Story".localizedFeed)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .onTapGesture {
                        showImagePickerOption = true
                    }
                }
                ForEach(0 ..< storiesUserState.users.count, id: \.self) { index in
                    let user = storiesUserState.users[index]
                    VStack(alignment: HorizontalAlignment.center) {
                        VStack {
                            if let profilePictureURL = user.profilePictureURL, !profilePictureURL.isEmpty {
                                GWSNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                                placeholderImage: UIImage(named: "empty-avatar")!,
                                                needUniqueID: true)
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                                    .frame(width: imageHeight, height: imageHeight)
                            } else {
                                Image("empty-avatar")
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: imageHeight, height: imageHeight)
                                    .id(UUID())
                            }
                        }
                        .padding(4)
                        .overlay(Circle().stroke(Color(UIColor(hexString: "#4991EC")), lineWidth: 2))
                        Text(user.uid == feedViewModel.loggedInUser?.uid ? "My Story".localizedFeed : user.fullName())
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .id(UUID())
                    }
                    .onTapGesture {
                        isStoryContentPresented = true
                        userStoriesIndex = index
                        selectedStories = storiesUserState.stories[userStoriesIndex]
                    }
                }
            }.padding(.horizontal, 5)
        }.id(feedViewModel.storyUpdatingTime)
    }
}
