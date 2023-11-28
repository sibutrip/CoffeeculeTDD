//
//  MemberListDetail.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/12/23.
//

import SwiftUI
import CloudKit

struct TransactionHistoryDetail: View {
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    let transaction: Transaction
    var buyer: User? {
        transaction.secondParent
    }
    var receiver: User? {
        transaction.thirdParent
    }
    var buyerName: String {
        buyer?.name ?? ""
    }
    var buyerIcon: MugIcon {
        buyer?.mugIcon ?? .disposable
    }
    var buyerColor: UserColor {
        buyer?.userColor ?? .purple
    }
    var receiverName: String {
        receiver?.name ?? ""
    }
    var receiverIcon: MugIcon {
        receiver?.mugIcon ?? .disposable
    }
    var receiverColor: UserColor {
        receiver?.userColor ?? .purple
    }
    
    @State private var textSize: CGSize = .zero
    var body: some View {
        HStack {
            ZStack {
                Image(receiverIcon.selectedImageBackground)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color("user.background"))
                Image(receiverIcon.selectedImage)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color(receiverColor.colorName))
                
            }
            ChildSizeReader(size: $textSize) {
                Text(receiverName)
                    .font(.title2)
//                    .padding(.vertical)
                    .foregroundStyle(Color(receiverColor.colorName))
            }
            Spacer()
            Label("Received coffee from", systemImage: "arrow.left")
                .labelStyle(.iconOnly)
            Spacer()
            ChildSizeReader(size: $textSize) {
                Text(buyerName)
                    .font(.title2)
//                    .padding(.vertical)
                    .foregroundStyle(Color(buyerColor.colorName))
            }
            ZStack {
                Image(buyerIcon.selectedImageBackground)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color("user.background"))
                Image(buyerIcon.selectedImage)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color(buyerColor.colorName))
//            }
//            .overlay {
                Image(buyerIcon.isBuyingBadgeImage)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
//                    .offset(x: -textSize.height / 2, y: -textSize.height / 2)
            }
        }
    }
}

#Preview {
    TransactionHistoryDetail(transaction: Transaction(from: CKRecord(recordType: "test"))!)
}
