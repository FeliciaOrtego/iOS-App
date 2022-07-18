//
//  GWSNewPostView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 30/04/21.
//

import SwiftUI
import YPImagePicker

struct GWSNewPostView: View {
    @Binding var selectedItems: [YPMediaItem]
    @Binding var isNewPostPresented: Bool
    @State var captionText: String = ""
    var viewer: GWSUser?
    @ObservedObject private var viewModel: GWSNewPostViewModel
    @State var postComposer = GWSPostComposerState()
    @State var isAddLocationPresented: Bool = false
    @State var locationText: String = ""
    @State var showLocationText: Bool = false
    var appConfig: GWSConfigurationProtocol

    init(selectedItems: Binding<[YPMediaItem]>, isNewPostPresented: Binding<Bool>, viewer: GWSUser?, appConfig: GWSConfigurationProtocol) {
        _selectedItems = selectedItems
        _isNewPostPresented = isNewPostPresented
        self.viewer = viewer
        self.appConfig = appConfig
        viewModel = GWSNewPostViewModel(isNewPostPresented: _isNewPostPresented)
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack(alignment: VerticalAlignment.top) {
                    if let firstItem = selectedItems.first {
                        switch firstItem {
                        case let .photo(photo):
                            Image(uiImage: photo.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                        case let .video(video):
                            let assetURL = video.url
                            Image(uiImage: video.thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                        }
                    }
                    ZStack(alignment: .leading) {
                        if captionText.isEmpty {
                            VStack {
                                HStack {
                                    Text("Write a caption...".localizedFeed)
                                        .padding(.top, 10)
                                        .padding(.leading, 2)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                        TextEditor(text: $captionText)
                            .opacity(captionText.isEmpty ? 0.25 : 1)
                    }.frame(height: 100)
                }.padding()
                Divider()
                HStack {
                    VStack {
                        HStack {
                            Text("Add location".localizedFeed)
                            Spacer()
                        }
                        if showLocationText {
                            HStack {
                                Text(locationText)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                    }
                    if showLocationText {
                        Image(systemName: "multiply")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.gray)
                            .onTapGesture {
                                self.locationText = ""
                                self.showLocationText = !self.locationText.isEmpty
                                self.postComposer.latitude = nil
                                self.postComposer.longitude = nil
                                self.postComposer.location = ""
                            }
                    } else {
                        Image("arrow-next-icon")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !showLocationText {
                        isAddLocationPresented = true
                    }
                }
                .padding()
                Divider()
                Spacer()
                EmptyView()
                    .fullScreenCover(isPresented: $isAddLocationPresented) {
                        LocationPickerView(locationText: $locationText, showLocationText: $showLocationText, postComposer: postComposer)
                    }
            }
            .navigationBarTitle("New Post".localizedFeed, displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                isNewPostPresented = false
            }) {
                Text("Cancel".localizedCore)
                    .foregroundColor(Color(appConfig.mainTextColor))
            }, trailing:
            Button(action: {
                var postMediaArray: [UIImage] = []
                var postVideoArray: [URL] = []

                for item in selectedItems {
                    switch item {
                    case let .photo(photo):
                        postMediaArray.append(photo.image)
                    case let .video(video):
                        let assetURL = video.url
                        postVideoArray.append(assetURL)
                    }
                }

                postComposer.postMedia = postMediaArray
                postComposer.postVideo = postVideoArray

                postComposer.postText = captionText
                postComposer.date = Date()

                viewModel.saveNewPost(user: viewer, postComposer: postComposer)
            }) {
                Text("Share".localizedFeed)
                    .foregroundColor(Color(appConfig.mainTextColor))
            })
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.isPostSharing ? 1 : 0)
        )
    }
}

struct LocationPickerView: UIViewControllerRepresentable {
    @Binding var locationText: String
    @Binding var showLocationText: Bool
    var postComposer: GWSPostComposerState

    func makeUIViewController(context _: Context) -> UIViewController {
        let viewController = LocationPicker()
        viewController.addBarButtons()
        viewController.pickCompletion = { pickedLocationItem in
            self.locationText = pickedLocationItem.name
            self.showLocationText = !self.locationText.isEmpty
            self.postComposer.latitude = pickedLocationItem.coordinate?.latitude
            self.postComposer.longitude = pickedLocationItem.coordinate?.longitude
            self.postComposer.location = pickedLocationItem.name
        }
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
