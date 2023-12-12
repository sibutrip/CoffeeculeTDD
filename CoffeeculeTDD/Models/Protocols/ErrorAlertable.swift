//
//  ErrorAlertable.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 12/12/23.
//

import SwiftUI

protocol ErrorAlertable {
    var errorTitle: String? { get nonmutating set }
    var errorMessage: String? { get nonmutating set }
    var isLoading: Bool { get nonmutating set }
}

extension ErrorAlertable {
    var showingError: Binding<Bool> {
        Binding {
            errorTitle != nil
        } set: { isShowingError in
            if !isShowingError {
                errorTitle = nil
                errorMessage = nil
            }
        }
    }
    
    @MainActor
    func displayAlertIfFails(for action: () throws -> Void) {
        do {
            try action()
        } catch {
            if let error = error as? LocalizedError {
                errorTitle = error.errorDescription
                errorMessage = error.recoverySuggestion
            } else { errorTitle = error.localizedDescription }
        }
    }
    func displayAlertIfFailsAsync(for action: @escaping () async throws -> Void) {
        Task {
            isLoading = true
            do { try await action() }
            catch {
                if let error = error as? LocalizedError {
                    errorTitle = error.errorDescription
                    errorMessage = error.recoverySuggestion
                } else { errorTitle = error.localizedDescription }
            }
            isLoading = false
        }
    }
}

extension View {
    @ViewBuilder func displaysAlertIfActionFails<Content: ErrorAlertable>(for content: Content) -> some View {
        if content.errorTitle == nil {
            self
        } else {
            self
                .alert(content.errorTitle ?? "", isPresented: content.showingError) {
                    Button("OK") { }
                } message: {
                    Text(content.errorMessage ?? "")
                }
        }
    }
}

extension View where Self: ErrorAlertable {
    var body: some View {
        body.displaysAlertIfActionFails(for: self)
    }
}
