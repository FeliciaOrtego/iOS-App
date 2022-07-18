//
//  GWSSearchBar.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 18/04/21.
//

import SwiftUI

struct GWSSearchBar: View {
    var placeHolder: String
    @Binding var text: String
    @State private var isEditing = false
    var completionHandler: ((String) -> Void)?
    var cancelHandler: (() -> Void)?
    var defaultCancelShow: Bool
    var appConfig: GWSConfigurationProtocol

    var body: some View {
        HStack {
            TextField(placeHolder, text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(appConfig.grey1))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        if isEditing {
                            Button(action: {
                                self.text = ""

                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
                .onTapGesture {
                    self.isEditing = true
                }
                .onChange(of: text) { searchText in
                    self.isEditing = !searchText.isEmpty
                    self.completionHandler?(searchText)
                }

            if defaultCancelShow || isEditing {
                Button(action: {
                    self.isEditing = false
                    self.text = ""

                    // Dismiss the keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    self.cancelHandler?()
                }) {
                    Text("Cancel".localizedCore)
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}
