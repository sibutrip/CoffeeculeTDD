//
//  MemberView.swift
//  Coffeecule
//
//  Created by Zoe Cutler on 9/7/23.
//

import SwiftUI
import CloudKit

struct MemberView: View {
    let someoneElseBuying: Bool
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @Binding var user: User
    var name: String {
        user.name
    }
    var icon: MugIcon {
        user.mugIcon
    }
    var color: UserColor {
        user.userColor
    }
    var isBuying: Bool {
        coffeeculeManager.selectedBuyer == user
    }
    
    var isPresent: Bool {
        coffeeculeManager.selectedUsers.contains(where: { $0.id == user.id })
    }
    
    @State private var zstackSize = CGSize(width: 100, height: 100)
    
    var body: some View {
        ZStack {
            ChildSizeReader(size: $zstackSize) {
                Group {
                    if isPresent {
                        Image(icon.selectedImageBackground)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("user.background"))
                        Image(icon.selectedImage)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(color.colorName))
                        
                        if isBuying {
                            Image(icon.isBuyingBadgeImage)
                                .resizable()
                                .scaledToFit()
                        } else if someoneElseBuying {
                            Image(icon.someoneElseBuyingBadgeImage)
                                .resizable()
                                .scaledToFit()
                        }
                    } else {
                        Image(icon.imageBackground)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("user.background"))
                        Image(icon.image)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(color.colorName))
                    }
                }
            }
            Text(name)
                .multilineTextAlignment(.center)
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(isPresent ? Color("background") : Color(color.colorName))
                .minimumScaleFactor(0.2)
                .lineLimit(1)
                .offset(x: icon.offsetPercentage.0 * zstackSize.width / 2, y: (icon.offsetPercentage.1 * zstackSize.height / 2))
                .frame(maxWidth: icon.maxWidthPercentage * zstackSize.width)
        }
        .animation(.default, value: coffeeculeManager.selectedBuyer)
    }
    init(with user: Binding<User>, someoneElseBuying: Bool = false) {
        _user = user
        self.someoneElseBuying = someoneElseBuying
    }
}
