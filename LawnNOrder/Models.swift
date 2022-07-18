//
//  Data.swift
//  LawnNOrder
//
//  Created by Jared Sullivan on 1/20/22.
//

import SwiftUI

enum StateList: String, CaseIterable, Identifiable {
    var id: Self { self }
    case alaska = "AK"
    case alabama = "AL"
    case arkansas = "AR"
    case americanSamoa = "AS"
    case arizona = "AZ"
    case california = "CA"
    case colorado = "CO"
    case connecticut = "CT"
    case districtOfColumbia = "DC"
    case delaware = "DE"
    case florida = "FL"
    case georgia = "GA"
    case guam = "GU"
    case hawaii = "HI"
    case iowa = "IA"
    case idaho = "ID"
    case illinois = "IL"
    case indiana = "IN"
    case kansas = "KS"
    case kentucky = "KY"
    case louisiana = "LA"
    case massachusetts = "MA"
    case maryland = "MD"
    case maine = "ME"
    case michigan = "MI"
    case minnesota = "MN"
    case missouri = "MO"
    case mississippi = "MS"
    case montana = "MT"
    case northCarolina = "NC"
    case northDakota = "ND"
    case nebraska = "NE"
    case newHampshire = "NH"
    case newJersey = "NJ"
    case newMexico = "NM"
    case nevada = "NV"
    case newYork = "NY"
    case ohio = "OH"
    case oklahoma = "OK"
    case oregon = "OR"
    case pennsylvania = "PA"
    case ruertoRico = "PR"
    case rhodeIsland = "RI"
    case southCarolina = "SC"
    case southDakota = "SD"
    case tennessee = "TN"
    case texas = "TX"
    case utah = "UT"
    case virginia = "VA"
    case virginIslands = "VI"
    case vermont = "VT"
    case washington = "WA"
    case wisconsin = "WI"
    case westVirginia = "WV"
    case wyoming = "WY"
}

enum FrequencyType: String, CaseIterable, Identifiable {
    var id: Self { self }
    case once = "Once"
    case biWeekly = "BiWeekly"
    case weekly = "Weekly"
    case biMonthly = "BiMonthly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnually = "SemiAnnually"
    case annually = "Annually"
}

struct CustomerViewModel: Codable, Identifiable, Equatable {
    let id: Int
    let displayName: String
    let firstName: String
    let lastName: String
    let displayAddress: String
    let address1: String
    let address2: String
    let city: String
    let state: String
    let zip: String
    let phone: String
    let email: String
    let products: [ProductViewModel]?

    static let defaultCustomer = CustomerViewModel(
        id: -1,
        displayName: "",
        firstName: "",
        lastName: "",
        displayAddress: "",
        address1: "",
        address2: "",
        city: "",
        state: "",
        zip: "",
        phone: "",
        email: "",
        products: [ProductViewModel]()
    )
}

struct CustomerDTO: Codable {
    let companyId: Int
    let firstName: String
    let lastName: String
    let address1: String
    let address2: String
    let city: String
    let state: String
    let zip: String
    let phone: String
    let email: String

    static let defaultCustomer = CustomerDTO(
        companyId: -1,
        firstName: "",
        lastName: "",
        address1: "",
        address2: "",
        city: "",
        state: "",
        zip: "",
        phone: "",
        email: ""
    )
}

struct CustomerEditDTO: Codable {
    let id: Int
    let companyId: Int
    let firstName: String
    let lastName: String
    let address1: String
    let address2: String
    let city: String
    let state: String
    let zip: String
    let phone: String
    let email: String

    static let defaultCustomer = CustomerEditDTO(
        id: -1,
        companyId: -1,
        firstName: "",
        lastName: "",
        address1: "",
        address2: "",
        city: "",
        state: "",
        zip: "",
        phone: "",
        email: ""
    )
}

struct Company: Codable, Identifiable {
    let id: Int
    let name: String
    let address1: String
    let address2: String
    let city: String
    let state: String
    let zip: String
    let phone: String
    let email: String
    let poc: String

    static let defaultCompany = Company(
        id: -1,
        name: "",
        address1: "",
        address2: "",
        city: "",
        state: "",
        zip: "",
        phone: "",
        email: "",
        poc: ""
    )
}

struct InvoiceViewModel: Identifiable, Codable, Hashable {
    let id: Int
    let prettyNumber: String
    let customerId: Int
    let customerDisplayName: String
    let customerDisplayAddress: String
    let subTotal: Int
    let totalPrice: Int
    let statusCd: String
    let sent: Bool
    let paid: Bool
    let pastDue: Bool
    let generatedDate: String
    let dueDate: String
    let surchargeText: String
    let jobs: [JobViewModel]?

    static let defaultInvoice =
        InvoiceViewModel(
            id: -1,
            prettyNumber: "",
            customerId: -1,
            customerDisplayName: "",
            customerDisplayAddress: "",
            subTotal: 0,
            totalPrice: 0,
            statusCd: "",
            sent: false,
            paid: false,
            pastDue: false,
            generatedDate: "",
            dueDate: "",
            surchargeText: "",
            jobs: [JobViewModel]()
        )
}

struct InvoiceDTO: Codable {
    let companyId: Int
    let customerId: Int
    let serviceDate: String
    let teamId: Int
    let jobProductIds: [Int]

    static let defaultInvoice =
        InvoiceDTO(
            companyId: -1,
            customerId: -1,
            serviceDate: "",
            teamId: -1,
            jobProductIds: [Int]()
        )
}

struct InvoiceEditDTO: Codable, Identifiable {
    let id: Int
    let companyId: Int
    let prettyNumber: String
    let statusCd: String
    let sent: Bool
    let paid: Bool
    let pastDue: Bool
    let final: Bool

    static let defaultInvoice =
        InvoiceEditDTO(
            id: -1,
            companyId: -1,
            prettyNumber: "",
            statusCd: "",
            sent: false,
            paid: false,
            pastDue: false,
            final: false
        )
}

struct JobReOrderRequest: Codable {
    let jobIds: [Int]
    let routeOrders: [Int]
}

struct JobViewModel: Identifiable, Codable, Hashable {
    let id: Int
    let customerId: Int
    let customerDisplayName: String
    let customerDisplayAddress: String
    let customerScheduleId: Int
    let serviceDate: String
    let serviceCompleteDate: String?
    let frequency: Int
    let teamId: Int
    let teamNameDisplayString: String
    let productListDisplayString: String
    let products: [ProductViewModel]?
    let invoiceId: Int
    let description: String?
    let routeOrder: Int?
    let statusCd: String?

    static let defaultJob = JobViewModel(
        id: -1,
        customerId: -1,
        customerDisplayName: "",
        customerDisplayAddress: "",
        customerScheduleId: -1,
        serviceDate: "",
        serviceCompleteDate: "",
        frequency: -1,
        teamId: -1,
        teamNameDisplayString: "",
        productListDisplayString: "",
        products: [ProductViewModel](),
        invoiceId: -1,
        description: "",
        routeOrder: -1,
        statusCd: ""
    )
}

struct JobsReOrderDTO: Encodable {
    let jobIds: [Int]
    let routeOrders: [Int]
    let serviceDates: [String]
    let statusCds: [String]

    static let defaultJob = JobsReOrderDTO(
        jobIds: [Int](),
        routeOrders: [Int](),
        serviceDates: [String](),
        statusCds: [String]()
    )
}

struct JobDTO: Codable {
    let customerId: Int
    let companyId: Int
    let serviceDate: String
    let frequency: Int
    let teamId: Int
    let invoiceId: Int
    let productIds: [Int]

    static let defaultJob = JobDTO(
        customerId: -1,
        companyId: -1,
        serviceDate: "",
        frequency: -1,
        teamId: -1,
        invoiceId: -1,
        productIds: [Int]()
    )
}

struct JobEditDTO: Identifiable, Codable {
    let id: Int
    let companyId: Int
    let customerId: Int
    let serviceDate: String
    let serviceCompleteDate: String?
    let frequency: Int
    let teamId: Int
    let invoiceId: Int
    let statusCd: String?
    let description: String?

    static let defaultJob = JobEditDTO(
        id: -1,
        companyId: -1,
        customerId: -1,
        serviceDate: "",
        serviceCompleteDate: "",
        frequency: -1,
        teamId: -1,
        invoiceId: -1,
        statusCd: "",
        description: ""
    )
}

struct ProductViewModel: Codable, Identifiable, Hashable {
    let id: Int
    let jobId: Int?
    let productId: Int?
    let name: String
    let price: Int

    static let defaultProduct = ProductViewModel(
        id: -1,
        jobId: -1,
        productId: -1,
        name: "",
        price: -1
    )
}

struct JobProductAddDTO: Codable {
    let jobId: Int
    let productId: Int
    let price: Int

    static let defaultJobProduct = JobProductAddDTO(
        jobId: -1,
        productId: -1,
        price: -1
    )
}

struct ProductAddDTO: Codable {
    let companyId: Int
    let name: String
    let price: Int

    static let defaultProduct = ProductAddDTO(
        companyId: -1,
        name: "",
        price: -1
    )
}

struct CustomerProductAddDTO: Codable {
    let customerId: Int
    let productId: Int
    let price: Int

    static let defaultProduct = CustomerProductAddDTO(
        customerId: -1,
        productId: -1,
        price: -1
    )
}

struct CustomerScheduleProductAddDTO: Codable {
    let customerScheduleId: Int
    let productId: Int

    static let defaultCustomerScheduleProduct = CustomerScheduleProductAddDTO(
        customerScheduleId: -1,
        productId: -1
    )
}

struct CustomerScheduleProductEditDTO: Codable {
    let id: Int
    let customerScheduleId: Int
    let productId: Int

    static let defaultCustomerScheduleProduct = CustomerScheduleProductEditDTO(
        id: -1,
        customerScheduleId: -1,
        productId: -1
    )
}

struct ProductEditDTO: Identifiable, Codable {
    let id: Int
    let name: String
    let price: Int

    static let defaultProduct = ProductEditDTO(
        id: -1,
        name: "",
        price: -1
    )
}

struct TeamViewModel: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let companyId: Int
    let userLeadName: String
    let leadUserId: Int
    let leadYN: Bool

    static let defaultTeam = TeamViewModel(
        id: -1,
        name: "",
        companyId: -1,
        userLeadName: "",
        leadUserId: -1,
        leadYN: false
    )
}

struct TeamDTO: Codable {
    let name: String
    let leadUserId: Int

    static let defaultTeam = TeamDTO(
        name: "",
        leadUserId: -1
    )
}

struct TeamEditDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let leadUserId: Int

    static let defaultTeam = TeamEditDTO(
        id: -1,
        name: "",
        leadUserId: -1
    )
}

struct ReportViewModel: Codable, Identifiable {
    let id: String
    let year: String
    let monthDigit: String
    let monthNameFull: String
    let monthNameShort: String
    let unPaid: Int
    let paid: Int
    let pastDue: Int
    let monthTotal: Int

    static let defaultReport = ReportViewModel(
        id: "-1",
        year: "2022",
        monthDigit: "01",
        monthNameFull: "January",
        monthNameShort: "Jan",
        unPaid: 0,
        paid: 0,
        pastDue: 0,
        monthTotal: 0
    )
}

struct SettingViewModel: Codable, Identifiable, Hashable {
    let id: Int
    let attribute: String
    let value: String

    static let defaultSetting = SettingViewModel(
        id: -1,
        attribute: "",
        value: ""
    )
}

struct UserViewModel: Codable, Identifiable {
    let id: Int
    let companyId: Int
    let name: String
    let phone: String
    let email: String
    let adminYN: Bool

    static let defaultUser = UserViewModel(
        id: -1,
        companyId: -1,
        name: "",
        phone: "",
        email: "",
        adminYN: false
    )
}

struct UserDTO: Codable {
    let name: String
    let phone: String
    let email: String

    static let defaultUser = UserDTO(
        name: "",
        phone: "",
        email: ""
    )
}

struct UserEditDTO: Identifiable, Codable {
    let id: Int
    let companyId: Int
    let name: String
    let phone: String
    let email: String
    let adminYN: Bool

    static let defaultUser = UserEditDTO(
        id: -1,
        companyId: -1,
        name: "",
        phone: "",
        email: "",
        adminYN: false
    )
}

struct AuthResponse: Codable {
    let id: Int
    let name: String
    let email: String
    let token: String
    let success: Bool

    static let defaultAuthResponse = AuthResponse(
        id: -1,
        name: "",
        email: "",
        token: "",
        success: false
    )
}

struct JWTToken: Codable {
    let teamId: Int
    let exp: Int
    let iat: Int
    let isAdmin: String
    let nbf: Int
    let id: Int

    static let defaultJWTToken = JWTToken(
        teamId: -1, exp: -1, iat: -1, isAdmin: "Y", nbf: -1, id: -1
    )
}

struct AuthRequest: Codable {
    let email: String
    let companyId: Int

    static let defaultAuthRequest = AuthRequest(
        email: "",
        companyId: 1
    )
}

enum HttpError: Error {
    case badRequest
    case badJSON
    case badAuth
}
