//
//  CupPickerDetail.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import SwiftUI
import CloudKit

struct CupPickerDetail: View {
    @Binding var user: User?
    let icon: MugIcon
    var isSelected: Bool {
        user?.mugIcon == icon
    }
    @State private var zstackSize: CGSize = .zero
    var body: some View {
        ChildSizeReader(size: $zstackSize) {
            
            ZStack {
                if let user {
                    if isSelected {
                        Image(icon.selectedImageBackground)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("user.background"))
                        Image(icon.selectedImage)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(user.userColor.colorName))
                        Text(user.name)
                            .multilineTextAlignment(.center)
                            .font(.title.weight(.semibold))
                            .foregroundColor(Color("background"))
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                            .offset(x: icon.offsetPercentage.0 * zstackSize.width / 2, y: icon.offsetPercentage.1 * zstackSize.height / 2)
                            .frame(maxWidth: icon.maxWidthPercentage * zstackSize.width)
                    } else {
                        Image(icon.imageBackground)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("user.background"))
                        Image(icon.image)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(user.userColor.colorName))
                    }
                }
            }
        }
        .animation(.default, value: isSelected)
    }
}

#Preview {
    CupPickerDetail(user: .constant(User(systemUserID: "Test")), icon: .disposable)
}
