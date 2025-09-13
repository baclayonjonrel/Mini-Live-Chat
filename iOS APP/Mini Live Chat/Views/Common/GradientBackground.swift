//
//  GradientBackground.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/22/25.
//


import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.red.opacity(0.7),
                Color.blue.opacity(0.7)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
