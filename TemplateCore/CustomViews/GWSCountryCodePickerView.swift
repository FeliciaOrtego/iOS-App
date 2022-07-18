//
//  GWSCountryCodePickerView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 06/04/21.
//

import SwiftUI

public struct Country: Equatable, Identifiable {
    public let id = UUID()
    public let name: String
    public let code: String
    public let phoneCode: String
    public func localizedName(_ locale: Locale = Locale.current) -> String? {
        return locale.localizedString(forRegionCode: code)
    }

    public var flag: UIImage {
        return UIImage(named: "\(code.uppercased())")!
    }
}

struct GWSCountryCodePickerView: View {
    @Binding var phoneCountryCodeString: String
    @Binding var phoneCodeString: String
    @Binding var showingCountryPicker: Bool
    @Binding var showingSheet: Bool

    public let countries: [Country] = {
        var countries = [Country]()
        guard let jsonPath = Bundle.main.path(forResource: "CountryCodes", ofType: "json"),
              let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath))
        else {
            return countries
        }

        if let jsonObjects = (try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization
                .ReadingOptions.allowFragments)) as? [Any]
        {
            for jsonObject in jsonObjects {
                guard let countryObj = jsonObject as? [String: Any] else {
                    continue
                }

                guard let name = countryObj["name"] as? String,
                      let code = countryObj["code"] as? String,
                      let phoneCode = countryObj["dial_code"] as? String
                else {
                    continue
                }

                let country = Country(name: name, code: code, phoneCode: phoneCode)
                countries.append(country)
            }
        }
        return countries
    }()

    var body: some View {
        List {
            ForEach(countries) { country in
                HStack {
                    Text(country.name)
                    Spacer()
                    Text(country.phoneCode)
                }.contentShape(Rectangle())
                    .onTapGesture {
                        phoneCountryCodeString = country.code
                        phoneCodeString = country.phoneCode
                        showingCountryPicker = false
                        showingSheet = false
                    }
            }
        }
    }
}
