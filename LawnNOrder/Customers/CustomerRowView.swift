//
//  CustomerRow.swift
//  LawnNOrder
//
//  Created by Luke Winkelmann on 1/22/22.
//

import SwiftUI

struct CustomerRowView: View {
    var customer: CustomerViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(customer.displayName)
                .font(.system(size: 16))
            Spacer()
            Text(customer.displayAddress)
                .font(.system(size: 14, weight: .light))
        }
    }
}
