//
//  GWSChatFriendsView.swift
//  ChatApp
//
//  Created by Jared Sullivan and Mayil Kannan on 22/07/21.
//

import SwiftUI

struct GWSChatFriendsView: View {
    @ObservedObject var store: GWSPersistentStore
    var viewer: GWSUser?
    @ObservedObject private var viewModel: GWSChatFriendsViewModel
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
        self.viewModel.isFollowersFollowingEnabled = isFollowersFollowingEnabled
        self.viewModel.showFollowers = showFollowers
        self.viewModel.loggedInUser = loggedInUser
        self.viewModel.showUsersWithOutFollowers = showUsersWithOutFollowers
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    if showUsersWithOutFollowers {
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
                    if !viewModel.showLoader {
                        if showUsersWithOutFollowers {
                            LazyVStack {
                                ForEach(viewModel.filteredAllUsers, id: \.self) { user in
                                    GWSChatFriendView(friendship: nil, viewer: viewer, user: user, viewModel: viewModel, appConfig: appConfig)
                                }
                            }
                        } else {
                            if viewModel.friendships.count == 0 {
                                GWSEmptyView(title: "No Friends".localizedChat, subTitle: "Make some friend requests and have your friends accept them. All your friends will show up here.".localizedChat, buttonTitle: "Find Friends".localizedChat, appConfig: appConfig, completionHandler: {
                                    if !showUsersWithOutFollowers {
                                        showUsersWithOutFollowersModal = true
                                    }
                                })
                                .padding(.top, 50)
                            }
                            LazyVStack {
                                ForEach(viewModel.friendships, id: \.self) { friendship in
                                    NavigationLink(destination: GWSChatThreadView(viewer: viewer, channel: getChannel(user: friendship.otherUser), appConfig: appConfig)) {
                                        GWSChatFriendView(friendship: friendship, viewer: friendship.currentUser, user: friendship.otherUser, viewModel: viewModel, appConfig: appConfig)
                                    }
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
                        self.viewModel.fetchFriendships(viewer: viewer)
                        self.viewModel.isFriendsListUpdated = true
                    }
                }
            }
            .navigationBarTitle("Contacts".localizedChat, displayMode: .inline)
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
                ) : AnyView(EmptyView()))
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
