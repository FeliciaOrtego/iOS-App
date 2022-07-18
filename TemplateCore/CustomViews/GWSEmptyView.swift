//
//  GWSEmptyView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 09/04/21.
//

import SwiftUI

struct GWSEmptyView: View {
    var title: String
    var subTitle: String
    var buttonTitle: String
    var hideButton: Bool = false
    var appConfig: GWSConfigurationProtocol
    var completionHandler: (() -> Void)?

    var body: some View {
        VStack {
            Text(title)
                .padding(.top, 30)
                .font(.system(size: 30, weight: .bold))
            Text(subTitle)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 50)
            if !hideButton {
                Button(action: {
                    completionHandler?()
                }) {
                    Text(buttonTitle)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 45)
                .foregroundColor(Color.white)
                .background(Color(appConfig.mainThemeForegroundColor))
                .cornerRadius(10)
                .padding(.horizontal, 50)
                .padding(.top, 20)
            }
        }
    }
}
