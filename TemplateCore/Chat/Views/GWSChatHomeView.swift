//
//  GWSChatHomeView.swift
//  ChatApp
//
//  Created by Jared Sullivan and Mayil Kannan on 19/07/21.
//

import SwiftUI

struct GWSChatHomeView: View {
    @ObservedObject var store: GWSPersistentStore
    var viewer: GWSUser?
    @ObservedObject private var viewModel: GWSChatFriendsViewModel
    @ObservedObject private var conversationViewModel: GWSConversationsViewModel
    @State var searchText: String = ""
    var showUsersWithOutFollowers = false
    @State private var showUsersWithOutFollowersModal: Bool = false
    var appConfig: GWSConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(store: GWSPersistentStore, loggedInUser: GWSUser?, viewer: GWSUser?, showUsersWithOutFollowers: Bool = false, viewModel: GWSChatFriendsViewModel? = nil, isFollowersFollowingEnabled: Bool = false, showFollowers: Bool = false, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.showUsersWithOutFollowers = showUsersWithOutFollowers
        self.appConfig = appConfig
        if let viewModel = viewModel {
            self.viewModel = viewModel
        } else {
            self.viewModel = GWSChatFriendsViewModel()
        }
        conversationViewModel = GWSConversationsViewModel(user: viewer)
        self.viewModel.isFollowersFollowingEnabled = isFollowersFollowingEnabled
        self.viewModel.showFollowers = showFollowers
        self.viewModel.loggedInUser = loggedInUser
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    if !viewModel.isFollowersFollowingEnabled {
                        ZStack {
                            GWSSearchBar(placeHolder: "Search for friends".localizedChat, text: $searchText, completionHandler: { searchText in
                                if showUsersWithOutFollowers {
                                    if searchText.isEmpty {
                                        viewModel.filteredAllUsers = viewModel.filteredOutBoundAllUsers
                                    } else {
                                        viewModel.filteredAllUsers = viewModel.filteredOutBoundAllUsers.filter { user -> Bool in
                                            user.fullName().contains(searchText)
                                        }
                                    }
                                }
                            }, cancelHandler: {
                                self.presentationMode.wrappedValue.dismiss()
                            }, defaultCancelShow: showUsersWithOutFollowers, appConfig: appConfig)
                                .padding([.leading, .trailing], 5)
                                .padding(.top, showUsersWithOutFollowers ? 10 : 5)
                                .allowsHitTesting(showUsersWithOutFollowers)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !showUsersWithOutFollowers {
                                showUsersWithOutFollowersModal = true
                            }
                        }
                    } else {
                        Spacer()
                            .frame(height: 10)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack {
                            if !viewModel.showLoader {
                                LazyHStack {
                                    ForEach(viewModel.friends, id: \.self) { user in
                                        NavigationLink(destination: GWSChatThreadView(viewer: viewer, channel: getChannel(user: user), appConfig: appConfig)) {
                                            GWSRoundedFriendsView(user: user)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }.id(viewModel.updatingTime)
                    }
                    .onAppear {
                        if showUsersWithOutFollowers {
                            self.viewModel.fetchAllUsers(viewer: viewer)
                        } else {
                            if !self.viewModel.isFriendsListUpdated {
                                self.viewModel.fetchFriends(viewer: viewer)
                                self.viewModel.isFriendsListUpdated = true
                            }
                        }
                    }
                    VStack {
                        if !conversationViewModel.showLoader {
                            if conversationViewModel.channels.count == 0 {
                                GWSEmptyView(title: "No Conversations".localizedChat, subTitle: "Start chatting with the people you follow. Your conversations will show up here.".localizedChat, buttonTitle: "Find Friends".localizedChat, appConfig: appConfig, completionHandler: {})
                                    .padding(.top, 50)
                            }
                            LazyVStack {
                                ForEach(conversationViewModel.channels) { channel in
                                    GWSConversationView(channel: channel, viewer: viewer, appConfig: appConfig)
                                }
                            }
                        }
                        Spacer()
                    }.id(conversationViewModel.updatingTime)
                        .navigationBarTitle((!viewModel.isFollowersFollowingEnabled ? "People" : viewModel.showFollowers ? "Followers" : "Following").localizedChat, displayMode: .inline)
                        .navigationBarHidden(showUsersWithOutFollowers)
                        .navigationBarItems(leading: viewModel.isFollowersFollowingEnabled ?
                            AnyView(
                                Button(action: {
                                    self.presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image("arrow-back-icon")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(Color(appConfig.mainThemeForegroundColor))
                                }
                            ) : AnyView(EmptyView()),
                            trailing:
                            NavigationLink(destination: GWSChatGroupMembersView(viewer: viewer, appConfig: appConfig, isChatApp: true)) {
                                Image("inscription")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(Color(appConfig.mainTextColor))
                            })
                }
            }
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(((!showUsersWithOutFollowers && viewModel.showLoader) || showUsersWithOutFollowers && viewModel.isAllUsersFetching) ? 1 : 0)
        )
        .fullScreenCover(isPresented: self.$showUsersWithOutFollowersModal) {
            GWSChatFriendsView(store: store, loggedInUser: viewModel.loggedInUser, viewer: viewer, showUsersWithOutFollowers: true, viewModel: viewModel, appConfig: appConfig)
        }
        .navigationBarHidden(viewModel.isFollowersFollowingEnabled)
    }

    func getChannel(user: GWSUser) -> GWSChatChannel {
        if let viewer = viewer {
            let id1 = (viewer.uid ?? "")
            let id2 = (user.uid ?? "")
            let channelId = id1 < id2 ? id1 + id2 : id2 + id1
            let channel = GWSChatChannel(id: channelId, name: user.fullName())
            channel.participants = [viewer, user]
            return channel
        }
        return GWSChatChannel(id: "", name: "")
    }
}

struct GWSRoundedFriendsView: View {
    var user: GWSUser
    let imageHeight: CGFloat = 58

    var body: some View {
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
            Text(user.fullName())
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .id(UUID())
        }
    }
}
