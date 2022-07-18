//
//  UserRow.swift
//  LawnNOrder
//
//  Created by Luke Winkelmann on 1/22/22.
//

import SwiftUI

struct TeamRowView: View {
    var team: TeamViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(team.name)
                Text(team.userLeadName)
                    .font(.system(size: 14, weight: .light))
            }
        }
    }
}
