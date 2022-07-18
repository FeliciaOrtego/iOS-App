//
//  ProductRow.swift
//  LawnNOrder
//
//  Created by Luke Winkelmann on 1/22/22.
//

import SwiftUI

struct ProductRowView: View {
    var product: ProductViewModel
    private let numberFormatter: NumberFormatter

    init(product: ProductViewModel) {
        self.product = product
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.system(size: 14, weight: .light))
            }
            Text(self.numberFormatter.string(from: Float(product.price) / 100 as NSNumber) ?? "0.00")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
