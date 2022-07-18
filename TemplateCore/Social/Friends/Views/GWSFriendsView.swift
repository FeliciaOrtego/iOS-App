//
//  FriendsView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 18/04/21.
//

import SwiftUI

struct GWSFriendsView: View {
    @ObservedObject var store: GWSPersistentStore
    var viewer: GWSUser?
    @ObservedObject private var viewModel: GWSFriendsViewModel
    @State var searchText: String = ""
    var showUsersWithOutFollowers = false
    @State private var showUsersWithOutFollowersModal: Bool = false
    var appConfig: GWSConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(store: GWSPersistentStore, loggedInUser: GWSUser?, viewer: GWSUser?, showUsersWithOutFollowers: Bool = false, viewModel: GWSFriendsViewModel? = nil, isFollowersFollowingEnabled: Bool = false, showFollowers: Bool = false, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.showUsersWithOutFollowers = showUsersWithOutFollowers
        self.appConfig = appConfig
        if let viewModel = viewModel {
            self.viewModel = viewModel
        } else {
            self.viewModel = GWSFriendsViewModel()
        }
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
                    if !viewModel.showLoader {
                        if !showUsersWithOutFollowers {
                            if viewModel.filteredInBoundUsers.count == 0 && viewModel.outBoundUsers.count == 0 {
                                GWSEmptyView(title: "No Friends".localizedChat, subTitle: "Make some friend requests and have your friends accept them. All your friends will show up here.".localizedChat, buttonTitle: "Find Friends".localizedChat, appConfig: appConfig, completionHandler: {
                                    if !showUsersWithOutFollowers {
                                        showUsersWithOutFollowersModal = true
                                    }
                                })
                                .padding(.top, 50)
                            }
                            LazyVStack {
                                ForEach(viewModel.filteredInBoundUsers, id: \.self) { user in
                                    if showUsersWithOutFollowers {
                                        GWSFriendView(viewer: viewer, user: user, viewModel: viewModel, appConfig: appConfig)
                                    } else {
                                        NavigationLink(destination: GWSProfileView(store: store, loggedInUser: viewModel.loggedInUser, viewer: user, isFollowing: false, hideNavigationBar: true, appConfig: appConfig)) {
                                            GWSFriendView(viewer: viewer, user: user, viewModel: viewModel, appConfig: appConfig)
                                        }
                                    }
                                }
                                ForEach(viewModel.outBoundUsers, id: \.self) { user in
                                    if showUsersWithOutFollowers {
                                        GWSFriendView(viewer: viewer, user: user, viewModel: viewModel, appConfig: appConfig)
                                    } else {
                                        NavigationLink(destination: GWSProfileView(store: store, loggedInUser: viewModel.loggedInUser, viewer: user, hideNavigationBar: true, appConfig: appConfig)) {
                                            GWSFriendView(viewer: viewer, user: user, viewModel: viewModel, appConfig: appConfig)
                                        }
                                    }
                                }
                            }
                        } else {
                            LazyVStack {
                                ForEach(viewModel.filteredAllUsers, id: \.self) { user in
                                    if showUsersWithOutFollowers {
                                        GWSFriendView(viewer: viewer, user: user, viewModel: viewModel, appConfig: appConfig)
                                    } else {
                                        NavigationLink(destination: GWSProfileView(store: store, loggedInUser: viewModel.loggedInUser, viewer: user, hideNavigationBar: true, appConfig: appConfig)) {
                                            GWSFriendView(viewer: viewer, user: user, viewModel: viewModel, appConfig: appConfig)
                                        }
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
                        self.viewModel.fetchFriends(viewer: viewer)
                        self.viewModel.isFriendsListUpdated = true
                    }
                }
            }
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
            GWSFriendsView(store: store, loggedInUser: viewModel.loggedInUser, viewer: viewer, showUsersWithOutFollowers: true, viewModel: viewModel, appConfig: appConfig)
        }
        .navigationBarHidden(viewModel.isFollowersFollowingEnabled)
    }
}
