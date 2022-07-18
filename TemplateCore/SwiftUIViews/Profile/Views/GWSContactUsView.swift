//
//  GWSContactUsView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 05/06/21.
//

import SwiftUI

struct GWSContactUsView: View {
    var body: some View {
        Form {
            Section(header: Text("Contact".localizedFeed)) {
                HStack {
                    Text("Address".localizedFeed)
                        .font(.system(size: 15))
                    Spacer()
                    Text("1710 Corporate Crossing, Suite #3, O'Falllon, IL, 62269")
                        .font(.system(size: 15))
                }
                HStack {
                    Text("E-mail us".localizedFeed)
                        .font(.system(size: 15))
                    Spacer()
                    Text("contact@gatewaysolutions.com")
                        .font(.system(size: 15))
                }
            }
            Section(header: Text("")) {
                Button(action: {
                    guard let number = URL(string: "tel://+16187262126") else { return }
                    UIApplication.shared.open(number)
                }) {
                    HStack {
                        Spacer()
                        Text("Call Us".localizedFeed)
                        Spacer()
                    }
                }
            }
        }.navigationBarTitle("Contact Us".localizedFeed)
    }
}
