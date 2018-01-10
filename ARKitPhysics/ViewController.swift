//
//  ViewController.swift
//  ARKitPhysics
//
//  Created by Jayven Nhan on 12/24/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    var planeNodes = [SCNNode]()
    
    // TODO: Declare rocketship node name constant
    let rocketshipNodeName = "rocketship"
    
    // TODO: Initialize an empty array of type SCNNode
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTapGestureToSceneView()
        configureLighting()
        addSwipeGesturesToSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        sceneView.delegate = self
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addRocketshipToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // TODO: Create add swipe gestures to scene view method
    func addSwipeGesturesToSceneView() {
        let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.applyForceToRocketship(withGestureRecognizer:)))
        swipeUpGestureRecognizer.direction = .up
        sceneView.addGestureRecognizer(swipeUpGestureRecognizer)
        
        let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.launchRocketship(withGestureRecognizer:)))
        swipeDownGestureRecognizer.direction = .down
        sceneView.addGestureRecognizer(swipeDownGestureRecognizer)
    }

    @objc func addRocketshipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitTestResults.first else { return }
        
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y + 0.1
        let z = translation.z
        
        guard let rocketshipScene = SCNScene(named: "rocketship.scn"),
            let rocketshipNode = rocketshipScene.rootNode.childNode(withName: "rocketship", recursively: false)
            else { return }
        
        rocketshipNode.position = SCNVector3(x,y,z)
        
        // TODO: Attach physics body to rocketship node
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        rocketshipNode.physicsBody = physicsBody
        rocketshipNode.name = rocketshipNodeName
        
        sceneView.scene.rootNode.addChildNode(rocketshipNode)
    }
    
    // TODO: Create get rocketship node from swipe location method
    func getRocketshipNode(from swipeLocation: CGPoint) -> SCNNode? {
        let hitTestResults = sceneView.hitTest(swipeLocation)
        guard let parentNode = hitTestResults.first?.node.parent,
            parentNode.name == rocketshipNodeName
            else { return nil }
        return parentNode
    }
    
    // TODO: Create apply force to rocketship method
    @objc func applyForceToRocketship(withGestureRecognizer recognizer: UIGestureRecognizer) {
        // 1
        guard recognizer.state == .ended else { return }
        // 2
        let swipeLocation = recognizer.location(in: sceneView)
        // 3
        guard let rocketshipNode = getRocketshipNode(from: swipeLocation),
            let physicsBody = rocketshipNode.physicsBody
            else { return }
        // 4
        let direction = SCNVector3(0, 3, 0)
        physicsBody.applyForce(direction, asImpulse: true)
    }
    
    // TODO: Create launch rocketship method
    @objc func launchRocketship(withGestureRecognizer recognizer: UIGestureRecognizer) {
        // 1
        guard recognizer.state == .ended else { return }
        // 2
        let swipeLocation = recognizer.location(in: sceneView)
        guard let rocketshipNode = getRocketshipNode(from: swipeLocation),
            let physicsBody = rocketshipNode.physicsBody,
            let reactorParticleSystem = SCNParticleSystem(named: "reactor", inDirectory: nil),
            let engineNode = rocketshipNode.childNode(withName: "node2", recursively: false)
            else { return }
        // 3
        physicsBody.isAffectedByGravity = false
        physicsBody.damping = 0
        // 4
        reactorParticleSystem.colliderNodes = planeNodes
        // 5
        engineNode.addParticleSystem(reactorParticleSystem)
        // 6
        let action = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 3)
        action.timingMode = .easeInEaseOut
        rocketshipNode.runAction(action)
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.transparentWhite
        
        var planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // TODO: Update plane node
        update(&planeNode, withGeometry: plane, type: .static)
        
        node.addChildNode(planeNode)
        
        // TODO: Append plane node to plane nodes array if appropriate
        planeNodes.append(planeNode)
    }
    
    // TODO: Remove plane node from plane nodes array if appropriate
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor,
            let planeNode = node.childNodes.first
            else { return }
        planeNodes = planeNodes.filter { $0 != planeNode }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            var planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        
        planeNode.position = SCNVector3(x, y, z)

        update(&planeNode, withGeometry: plane, type: .static)
        
    }
    
    // TODO: Create update plane node method
    func update(_ node: inout SCNNode, withGeometry geometry: SCNGeometry, type: SCNPhysicsBodyType) {
        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: type, shape: shape)
        node.physicsBody = physicsBody
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentWhite: UIColor {
        return UIColor.white.withAlphaComponent(0.20)
    }
}
