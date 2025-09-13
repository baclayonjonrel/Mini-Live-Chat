//
//  CallButton.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/29/25.
//


import SwiftUI

struct CallButton: View {
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                isPressed.toggle()
                action()
            }
        }) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(color)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .shadow(radius: 5)
        }
    }
}
