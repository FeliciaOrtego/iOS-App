//
//  InvoiceJobProductView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 5/24/22.
//

import SwiftUI

struct InvoiceJobProductView: View {
    let products: [ProductViewModel]
    private let numberFormatter: NumberFormatter

    init(products: [ProductViewModel]) {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        self.products = products
    }

    var body: some View {
        ForEach(self.products) { product in
            HStack {
                Text(product.name)
                    .font(.system(size: 14, weight: .bold))
                Text(self.numberFormatter.string(from: Float(product.price) / 100 as NSNumber) ?? "0.00")
                    .font(.system(size: 14, weight: .light))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }.padding()
    }
}
