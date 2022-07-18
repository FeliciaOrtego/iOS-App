//
//  JobProductEditView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 4/10/22.
//

import SwiftUI

//
//  ProductAddView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 4/10/22.
//

import SwiftUI

struct JobProductDetailView: View {
    let job: JobViewModel
    @State var jobProducts = [ProductViewModel]()
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false
    private let numberFormatter: NumberFormatter

    init(job: JobViewModel) {
        self.job = job
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(jobProducts) { jobProduct in
                    NavigationLink {
                        JobProductEditView(jobProduct: jobProduct)
                    }
                    label: {
                        HStack {
                            Text(jobProduct.name)
                            Spacer()
                            Text(self.numberFormatter.string(from: Float(jobProduct.price) / 100 as NSNumber) ?? "0.00")
                        }
                    }
                }
            }
            .refreshable {
                let fetcher = JobProductManager(jobId: self.job.id)
                try? await fetcher.fetchData()
                self.jobProducts = fetcher.jobProductData
            }
            .toolbar {
                HStack {
                    NavigationLink {
                        JobProductAddView(job: self.job, customerId: self.job.customerId)
                    }
                    label: {
                        VStack {
                            Text("Add".localizedCore)
                                .contentShape(Rectangle())
                                .padding(5)
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationTitle("Job Products".localizedCore)
            .overlay(
                VStack {
                    CPKProgressHUDSwiftUI()
                }
                .frame(width: 100,
                       height: 100)
                .opacity(self.showProgress ? 1 : 0)
            )
            .onAppear {
                if !self.didAppear {
                    self.didAppear = true
                    Task {
                        let fetcher = JobProductManager(jobId: self.job.id)
                        self.showProgress = true
                        try? await fetcher.fetchData()
                        self.showProgress = false
                        self.jobProducts = fetcher.jobProductData
                    }
                }
            }
            .task {
                let fetcher = JobProductManager(jobId: self.job.id)
                try? await fetcher.fetchData()
                self.jobProducts = fetcher.jobProductData
            }
        }.navigationViewStyle(.stack)
    }
}
