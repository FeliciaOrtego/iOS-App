//
//  InvoiceDetail.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/27/22.
//

import SwiftUI

struct InvoiceDetailView: View {
    @ObservedObject var store: GWSPersistentStore
    @ObservedObject var invoiceFetcher: InvoiceManager
    @ObservedObject var jobFetcher: JobManager
    @State private var invoiceJobs = [JobViewModel]()

    var appConfig: GWSConfigurationProtocol

    @State private var invoice: InvoiceViewModel
    @State private var sendSuccess: Bool = false
    @State private var updateSuccess: Bool = false
    @State private var showProgress: Bool = false
    @State private var didAppear: Bool = false

    @Environment(\.presentationMode) var presentationMode
    private let numberFormatter: NumberFormatter

    private let printController: UIPrintInteractionController = .init()

    init(store: GWSPersistentStore, appConfig: GWSConfigurationProtocol, invoice: InvoiceViewModel) {
        self.store = store
        self.appConfig = appConfig
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        invoiceFetcher = InvoiceManager.shared
        jobFetcher = JobManager.shared
        _invoice = State(initialValue: invoice)

        let jobs = jobFetcher.jobData.filter { job in
            job.invoiceId == invoice.id
        }

        _invoiceJobs = State(initialValue: jobs)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    VStack {
                        Text("Lawn and Order Landscaping")
                            .font(.system(size: 24))
                        Text("Invoice for Services")
                            .font(.system(size: 22))
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Invoice ID: " + invoice.prettyNumber)
                                .font(.system(size: 18, weight: .light))
                            Text("Generated: " + invoice.generatedDate)
                                .font(.system(size: 18, weight: .light))
                        }
                    }
                    VStack {
                        Text("262 OFallon Troy Rd OFallon, IL, 62269")
                            .font(.system(size: 18, weight: .light))
                    }
                    VStack {
                        Text(invoice.customerDisplayName)
                            .font(.system(size: 20))
                        Text("Service Address: ")
                            .font(.system(size: 18, weight: .light))
                        Text(invoice.customerDisplayAddress)
                            .font(.system(size: 20))
                        HStack {
                            Text("Due Date: " + invoice.dueDate)
                                .font(.system(size: 20))
                        }
                    }
                    .padding()
                    VStack {
                        if self.invoiceJobs.count > 0 {
                            ForEach(self.invoiceJobs) { job in
                                if self.invoice.statusCd == "X" {
                                    NavigationLink {
                                        JobDetailView(store: store, appConfig: appConfig, job: job)
                                    }
                                    label: {
                                        VStack {
                                            Text("Service Date: " + (job.serviceCompleteDate ?? ""))
                                                .padding()
                                            InvoiceJobProductView(products: job.products ?? [ProductViewModel]())
                                        }.padding()
                                    }
                                } else {
                                    VStack {
                                        Text("Service Date: " + (job.serviceCompleteDate ?? ""))
                                            .padding()
                                        InvoiceJobProductView(products: job.products ?? [ProductViewModel]())
                                    }.padding()
                                }
                            }.padding()
                        } else {
                            Text("Loading jobs, please wait...".localizedCore)
                        }
                    }
                    VStack {
                        Text("Sub-Total: ... " + (self.numberFormatter.string(from: Float(invoice.subTotal) / 100 as NSNumber) ?? "$0.00"))
                        Text(invoice.surchargeText.localizedCore)
                        Text("Total Due: ... " + (self.numberFormatter.string(from: Float(invoice.totalPrice) / 100 as NSNumber) ?? "$0.00"))
                    }
                }
                .overlay(
                    VStack {
                        CPKProgressHUDSwiftUI()
                    }
                    .frame(width: 100,
                           height: 100)
                    .opacity(self.showProgress ? 1 : 0)
                )
            }
            .toolbar {
                HStack {
                    if self.invoice.statusCd == "X" {
                        NavigationLink {
                            JobAddView(customerId: self.invoice.customerId, customer: CustomerViewModel.defaultCustomer,
                                       isSchedule: false, isInvoiceInitialJob: false, invoiceId: self.invoice.id)
                        } label: {
                            VStack {
                                Text("Add Job".localizedCore)
                                    .contentShape(Rectangle())
                                    .padding(5)
                                Image(systemName: "plus")
                            }
                        }.tint(Color(UIColor(hexString: "#008000")))
                        Button {
                            Task(priority: .high) {
                                self.updateSuccess = false
                                self.showProgress = true
                                await markAsFinal(invoice: self.invoice)
                                self.showProgress = false
                                self.updateSuccess = self.invoiceFetcher.updateResponse
                            }
                        } label: {
                            VStack {
                                Text("Finalize".localizedCore)
                                    .contentShape(Rectangle())
                                Image(systemName: "hand.thumbsup")
                            }
                        }.tint(Color(UIColor(hexString: "#008000")))
                    } else {
                        Button {
                            Task(priority: .high) {
                                self.updateSuccess = false
                                self.showProgress = true
                                await markAsDraft(invoice: self.invoice)
                                self.showProgress = false
                                self.updateSuccess = self.invoiceFetcher.updateResponse
                            }
                        } label: {
                            VStack {
                                Text("Un-Finalize".localizedCore)
                                    .contentShape(Rectangle())
                                Image(systemName: "hand.thumbsdown")
                            }
                        }.tint(Color(UIColor(hexString: "#008000")))
                        Button {
                            Task(priority: .high) {
                                self.sendSuccess = false
                                self.showProgress = true
                                await sendInvoice(invoice: self.invoice)
                                self.showProgress = false
                                self.sendSuccess = self.invoiceFetcher.sendResponse
                            }
                        } label: {
                            VStack {
                                Text("Send".localizedCore)
                                    .contentShape(Rectangle())
                                Image(systemName: "paperplane")
                            }
                        }.tint(Color(UIColor(hexString: "#008000")))
                        if !self.invoice.pastDue {
                            Button {
                                Task(priority: .high) {
                                    self.updateSuccess = false
                                    self.showProgress = true
                                    await markAsPastDue(invoice: self.invoice)
                                    self.showProgress = false
                                    self.updateSuccess = self.invoiceFetcher.updateResponse
                                }
                            } label: {
                                VStack {
                                    Text("Past Due".localizedCore)
                                        .contentShape(Rectangle())
                                    Image(systemName: "alarm")
                                }
                            }.tint(Color(UIColor(hexString: "#008000")))
                        }
                        Button {
                            Task(priority: .high) {
                                self.showProgress = true
                                await downloadInvoice(invoiceId: self.invoice.id)
                                self.showProgress = false
                            }
                        } label: {
                            VStack {
                                Text("Print".localizedCore)
                                    .contentShape(Rectangle())
                                Image(systemName: "printer")
                            }
                        }.tint(Color(UIColor(hexString: "#008000")))
                        if !self.invoice.paid {
                            Button {
                                Task(priority: .high) {
                                    self.updateSuccess = false
                                    self.showProgress = true
                                    await markAsPaid(invoice: self.invoice)
                                    self.showProgress = false
                                    self.updateSuccess = self.invoiceFetcher.updateResponse
                                }
                            } label: {
                                VStack {
                                    Text("Paid".localizedCore)
                                        .contentShape(Rectangle())
                                    Image(systemName: "dollarsign.circle")
                                }
                            }.tint(Color(UIColor(hexString: "#008000")))
                        }
                    }
                }
            }
            .alert("Invoice Sent", isPresented: $sendSuccess) {
                Button("OK") {
                    self.sendSuccess = false
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            .alert("Invoice Updated", isPresented: $updateSuccess) {
                Button("OK") {
                    self.updateSuccess = false
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            .layoutPriority(100)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.sRGB, red: 150 / 255, green: 150 / 255, blue: 150 / 255, opacity: 0.1), lineWidth: 1)
            )
            .padding([.top, .horizontal])
            .onAppear {
                if !self.didAppear {
                    self.didAppear = true
                    Task {
                        print("getting jobs for invoice on view appear")
                        let fetcher = InvoiceJobManager(invoiceId: self.invoice.id)
                        try? await fetcher.fetchData()
                        self.invoiceJobs = fetcher.jobData
                    }
                }
            }
            .task {
                print("getting jobs for invoice on view task")
                let fetcher = InvoiceJobManager(invoiceId: self.invoice.id)
                self.showProgress = true
                try? await fetcher.fetchData()
                self.invoiceJobs = fetcher.jobData
                self.showProgress = false
            }
        }
    }

    func markAsDraft(invoice: InvoiceViewModel) async {
        print("markAsDraft")
        let updatedInvoice = InvoiceEditDTO(
            id: invoice.id,
            companyId: 1,
            prettyNumber: invoice.prettyNumber,
            statusCd: invoice.statusCd,
            sent: false,
            paid: false,
            pastDue: false,
            final: false
        )
        try? await invoiceFetcher.putInvoiceUpdate(invoice: updatedInvoice)
    }

    func markAsFinal(invoice: InvoiceViewModel) async {
        print("markAsFinal")
        try? await invoiceFetcher.putInvoiceFinalize(invoiceId: invoice.id)
    }

    func markAsPastDue(invoice: InvoiceViewModel) async {
        print("markAsPastDue")
        let updatedInvoice = InvoiceEditDTO(
            id: invoice.id,
            companyId: 1,
            prettyNumber: invoice.prettyNumber,
            statusCd: invoice.statusCd,
            sent: invoice.sent,
            paid: invoice.paid,
            pastDue: true,
            final: true
        )
        try? await invoiceFetcher.putInvoiceUpdate(invoice: updatedInvoice)
    }

    func downloadInvoice(invoiceId: Int) async {
        print("downloadInvoice")
        let url = URL(string: AuthManager.baseApiUrlStr + "export/file/1/0/" + String(invoiceId))
        return FileDownloader.loadFileSync(url: url!) { path, error in
            if let error = error {
                print("PDF File download error: \(error)")
            }
            if let path = path {
                print("PDF File downloaded to: \(path)")
                printInvoice(path: path)
            }
        }
    }

    func printInvoice(path: String) {
        let nsUrl = NSURL(fileURLWithPath: path)

        do {
            let printData = try Data(contentsOf: nsUrl as URL)
            if UIPrintInteractionController.canPrint(printData) {
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.jobName = "invoicePrintJob_" + String(invoice.id)
                printInfo.outputType = .photo

                let printController = UIPrintInteractionController.shared
                printController.printInfo = printInfo
                printController.showsNumberOfCopies = false

                printController.printingItem = printData

                printController.present(animated: true, completionHandler: nil)
            }
        } catch {
            print("printing error")
        }
    }

    func markAsPaid(invoice: InvoiceViewModel) async {
        print("markAsPaid")
        let updatedInvoice = InvoiceEditDTO(
            id: invoice.id,
            companyId: 1,
            prettyNumber: invoice.prettyNumber,
            statusCd: invoice.statusCd,
            sent: invoice.sent,
            paid: true,
            pastDue: invoice.pastDue,
            final: true
        )

        try? await invoiceFetcher.putInvoiceUpdate(invoice: updatedInvoice)
    }

    func sendInvoice(invoice: InvoiceViewModel) async {
        print("sendInvoice")
        try? await invoiceFetcher.sendInvoice(invoiceId: invoice.id)
    }
}
