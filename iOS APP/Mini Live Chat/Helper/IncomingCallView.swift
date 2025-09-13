//
//  IncomingCallView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/29/25.
//

import SwiftUI

struct IncomingCallView: View {
    @Environment(\.presentationMode) var presentationMode
    let callerName: String
    let callerImage: String?
    var onAccept: () -> Void
    var onDecline: () -> Void
    
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                if let imageName = callerImage {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 4)
                                .scaleEffect(pulse ? 1.3 : 1)
                                .opacity(pulse ? 0 : 1)
                                .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: false), value: pulse)
                        )
                        .onAppear {
                            pulse = true
                        }
                        .shadow(radius: 10)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 140, height: 140)
                }
                
                Text(callerName)
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 60) {
                    CallButton(systemImage: "xmark", color: .red) {
                        onDecline()
                    }
                    
                    CallButton(systemImage: "phone.fill.arrow.up.right", color: .green) {
                        onAccept()
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}
