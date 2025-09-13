//
//  OutgoingCallView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/29/25.
//

import SwiftUI

struct OutgoingCallView: View {
    @Environment(\.presentationMode) var presentationMode
    let calleeName: String
    let calleeImage: String?
    var onCancel: () -> Void
    
    @State private var animateRings = false
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                if let imageName = calleeImage {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.green.opacity(0.4), lineWidth: 4)
                                .scaleEffect(animateRings ? 1.4 : 1)
                                .opacity(animateRings ? 0 : 1)
                                .animation(Animation.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: animateRings)
                        )
                        .onAppear { animateRings = true }
                        .shadow(radius: 10)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 140, height: 140)
                }
                
                Text("Calling \(calleeName)...")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Spacer()
                
                CallButton(systemImage: "phone.down.fill", color: .red) {
                    presentationMode.wrappedValue.dismiss()
                    onCancel()
                }
                .padding(.bottom, 50)
            }
        }
    }
}

//struct CallViews_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            IncomingCallView(callerName: "Alice", callerImage: nil, onAccept: {}, onDecline: {})
//            OutgoingCallView(calleeName: "Bob", calleeImage: nil, onCancel: {})
//        }
//    }
//}
