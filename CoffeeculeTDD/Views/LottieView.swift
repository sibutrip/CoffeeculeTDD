//
//  LottieView.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 12/5/23.
//

import SwiftUI
import Lottie

struct LottieViewAnimated: UIViewRepresentable {
    
    let animationName: String
    var loopMode: LottieLoopMode = .loop
    @Binding var isShowing: Bool
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        
        let animationView = LottieAnimationView()
        let animation = LottieAnimation.named(animationName)
        
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.play { _ in
            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(1000))) {
                isShowing = false
            }
        }
                
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    init(animationName: String, loopMode: LottieLoopMode = .loop, isShowing: Binding<Bool> = .constant(true)) {
        _isShowing = isShowing
        self.animationName = animationName
        self.loopMode = loopMode
    }
}

struct LottieView: UIViewRepresentable {
    
    let animationName: String
    
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        
        let animationView = LottieAnimationView()
        let animation = LottieAnimation.named(animationName)
        
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
                
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

#Preview {
    LottieView(animationName: "CheersSplash")
}
