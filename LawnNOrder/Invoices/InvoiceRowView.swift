//
//  InvoiceRow.swift
//  LawnNOrder
//
//  Created by Luke Winkelmann on 1/22/22.
//

import SwiftUI

struct InvoiceRowView: View {
    var invoice: InvoiceViewModel

    private let numberFormatter: NumberFormatter

    init(invoice: InvoiceViewModel) {
        self.invoice = invoice
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(invoice.customerDisplayName)
                    .font(.system(size: 14, weight: .bold))
                Text("#" + invoice.prettyNumber)
                    .font(.system(size: 14, weight: .light))
            }
            Text(self.numberFormatter.string(from: Float(invoice.subTotal) / 100 as NSNumber) ?? "$0.00")
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(invoice.customerDisplayAddress)
                .font(.system(size: 14, weight: .light))
        }
    }
}
