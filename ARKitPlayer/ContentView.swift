//
//  ContentView.swift
//  ARKitPlayer
//
//  Created by Oscar Castillo on 18/9/24.
//

import SwiftUI
import SceneKit
import ARKit
import AVKit

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        
        let configuration = ARImageTrackingConfiguration()
        guard let arImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("No AR images found")
        }
        configuration.trackingImages = arImages
        sceneView.session.run(configuration)
        
        // Set up the audio session to ignore the mute switch
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        var videoPlayer: AVPlayer?
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let imageAnchor = anchor as? ARImageAnchor else { return }
            let referenceImage = imageAnchor.referenceImage
            
            guard referenceImage.name == "ironman" else { return }
            
            let videoNode = SCNNode()
            let videoPlane = SCNPlane(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height)
            videoNode.geometry = videoPlane
            
            guard let videoURL = Bundle.main.url(forResource: "ironbaby", withExtension: ".mp4") else { return }
            videoPlayer = AVPlayer(url: videoURL)
            videoPlayer?.volume = 0.2
            
            let videoMaterial = SCNMaterial()
            videoMaterial.diffuse.contents = videoPlayer
            videoMaterial.isDoubleSided = true
            videoPlane.materials = [videoMaterial]
            
            videoNode.eulerAngles.x = -.pi / 2
            node.addChildNode(videoNode)
            
            videoPlayer?.play()
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let imageAnchor = anchor as? ARImageAnchor else { return }
            if imageAnchor.isTracked {
                videoPlayer?.play()
            } else {
                videoPlayer?.pause()
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}
