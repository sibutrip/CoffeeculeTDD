//
//  ColorPickerDetail.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import SwiftUI
import CloudKit

struct ColorPickerDetail: View {
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @Environment(\.colorScheme) var colorScheme
    let color: UserColor
    var body: some View {
        Group {
            if color == coffeeculeManager.user?.userColor {
                Circle()
                    .foregroundColor(Color(color.colorName))
            } else {
                Circle()
                    .foregroundColor(Color(color.colorName))
                    .overlay {
                        Circle()
                            .foregroundStyle(colorScheme == .light ? .white : .black)
                            .padding(5)
                    }
            }
        }
    }
}

#Preview {
    ColorPickerDetail(color: .purple)
}
