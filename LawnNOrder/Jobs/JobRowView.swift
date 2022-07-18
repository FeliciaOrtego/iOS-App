//
//  JobRow.swift
//  LawnNOrder
//
//  Created by Luke Winkelmann on 1/22/22.
//

import SwiftUI

struct JobRowView: View {
    let job: JobViewModel
    let isSkinny: Bool
    @State private var frqString = ""

    init(job: JobViewModel, isSkinny: Bool) {
        self.job = job
        self.isSkinny = isSkinny
        _frqString = State(initialValue: job.frequency != 0 ?
            job.frequency == 2 ? "Bi-Weekly" :
            job.frequency > 1 ? "repeats every " + String(job.frequency) + " weeks" : "Weekly"
            : "Once")
    }

    var body: some View {
        HStack {
            if job.statusCd == "A" {
                Text(String(job.routeOrder ?? 0)).font(.system(size: 14))
                    .padding()
            }
            VStack(alignment: .leading) {
                HStack {
                    Text(job.customerDisplayName)
                        .font(.system(size: 14))
                    Text(self.frqString.localizedCore).truncationMode(.tail)
                        .font(.system(size: 14, weight: .light))
                    Text(job.serviceDate)
                        .font(.system(size: 14, weight: .light))
                }
                Text(job.customerDisplayAddress)
                    .font(.system(size: 14, weight: .bold))
                Text(job.teamNameDisplayString)
                    .font(.system(size: 14, weight: .light))
                if self.isSkinny == false {
                    HStack {
                        Text(job.productListDisplayString + " ")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                if job.statusCd == "S" {
                    Text(job.description ?? "")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}
