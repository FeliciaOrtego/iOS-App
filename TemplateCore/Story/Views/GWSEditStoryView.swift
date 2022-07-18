//
//  GWSEditStoryView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 17/06/21.
//

import SwiftUI

struct GWSEditStoryView: View {
    @Binding var isEditStoryViewPresented: Bool
    @Binding var editStoryImage: UIImage
    @ObservedObject private var viewModel = GWSEditStoryViewModel()
    var viewer: GWSUser?
    @ObservedObject var storyFeedViewModel: GWSFeedViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Image("dismissIcon")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .onTapGesture {
                            isEditStoryViewPresented = false
                        }
                    Spacer()
                }.padding(.leading, 20)
                    .padding(.top, 50)
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        let composerState = GWSStoryComposerState()
                        composerState.mediaType = "image"
                        composerState.photoMedia = editStoryImage
                        viewModel.saveStories(loggedInUser: viewer, storyComposer: composerState) {
                            isEditStoryViewPresented = false
                            self.storyFeedViewModel.fetchStories()
                        }
                    }) {
                        Text("Post")
                            .font(.system(size: 14))
                            .frame(width: 80)
                            .frame(height: 35)
                            .contentShape(Rectangle())
                            .foregroundColor(Color.black)
                            .background(Color(UIColor(hexString: "#D3D3D3")))
                            .cornerRadius(35 / 2)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 50)
            }.background(
                Image(uiImage: editStoryImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            ).overlay(
                VStack {
                    CPKProgressHUDSwiftUI()
                }
                .frame(width: 100,
                       height: 100)
                .opacity(viewModel.showLoader ? 1 : 0)
            )
        }.edgesIgnoringSafeArea(.all)
    }
}
