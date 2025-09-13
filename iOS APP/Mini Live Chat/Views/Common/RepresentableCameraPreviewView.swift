//
//  RepresentableCameraPreviewView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/22/25.
//

import SwiftUI
import SkyWayRoom

struct RepresentableCameraPreviewView: UIViewRepresentable {
    typealias Context = UIViewRepresentableContext<Self>
    class Cordinator: NSObject {
        let view: RepresentableCameraPreviewView
        init(view: RepresentableCameraPreviewView) {
            self.view = view
        }
    }
    func makeUIView(context: Context) -> CameraPreviewView {
        return CameraPreviewView()
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        CameraVideoSource.shared().attach(uiView)
    }
    
    func makeCoordinator() -> Cordinator {
        return Cordinator(view: self)
    }
    
    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: Cordinator) {
        CameraVideoSource.shared().detach(uiView)
    }
    
}
