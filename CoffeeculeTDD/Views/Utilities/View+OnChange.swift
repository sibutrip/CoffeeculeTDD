//
//  View+OnChange.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/29/23.
//

import SwiftUI

extension View {
    @MainActor @ViewBuilder func onChangeiOS17Compatible<V>(of value: V, perform action: @escaping (_ newValue: V) -> Void) -> some View where V : Equatable {
        if #available(iOS 17, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
            
        } else {
            self.onChange(of: value) { newValue in
                action(newValue)
            }
        }
    }
}
