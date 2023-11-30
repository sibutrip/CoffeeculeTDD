//
//  ColorPickerDetail.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import SwiftUI

struct ColorPickerDetail: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var user: User?
    let color: UserColor
    var body: some View {
        Group {
            if color == user?.userColor {
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
    ColorPickerDetail(user: .constant(User(systemUserID: "Test")), color: .purple)
}
