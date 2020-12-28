//
//  ViewController.swift
//  ART
//
//  Created by Кирилл Смирнов on 27.10.2020.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var diceArray = [SCNNode]()
    var xDelta = 0.1
    var zDelta = 0.1 //смещение

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("blaaaa")
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        //MARK: - удобные точки для понимания сканирования поверхности
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        
        
        
        //let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01) // 0.1 = 10cm
        
        /*
        let sphere = SCNSphere(radius: 0.3)
         
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "art.scnassets/8k_moon.jpg")
        
        sphere.materials = [material]
        
        let node = SCNNode()
        node.position = SCNVector3(0, 0.1, -0.99)
        
        node.geometry = sphere
        
        sceneView.scene.rootNode.addChildNode(node)
        */
        
        sceneView.autoenablesDefaultLighting = true
        
        


    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("bl")
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{ // поскольку isMultitouch false - хватаем первый из set а
            let touchLocation = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            if let hitResults = results.first{
                print("toched plane")
                
                // Create a new scene
                let diceScene = SCNScene(named: "art.scnassets/diceColladaS.scn")!
                
//                if (
//                    (xDelta - abs(Double(hitResults.worldTransform.columns.3.x)) > 0.01) ||
//                    (zDelta - abs(Double(hitResults.worldTransform.columns.3.z)) > 0.01)
//                ) {
                if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true){
                    diceNode.position = SCNVector3(
                        x: hitResults.worldTransform.columns.3.x,
                        y: hitResults.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                        z: hitResults.worldTransform.columns.3.z
                        )
                    diceArray.append(diceNode)
            
        
                sceneView.scene.rootNode.addChildNode(diceNode)
                 
                    roll(dice: diceNode)
                }
            }
        }
    }
    
    func rollAllCu(){
        if !diceArray.isEmpty{
            for dice in diceArray{
                roll(dice: dice)
            }
        }
    }
    
    func roll(dice: SCNNode){
        
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2) // на 90 градусов!
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2) // на 90 градусов!
        // вращать по оси Y не требуется,)
        
        dice.runAction(
            SCNAction.rotateBy(
                x: CGFloat(randomX * 3),
                y: 0,
                z: CGFloat(randomZ * 4), // цифры 7 и 9 случайно взяты из головы, чтобы анимация вращения была в несколько оборотов, а не только 90-270-360
                duration: 0.5)
            )
        
        xDelta = .random(in: -0.019...0.019)
        zDelta = .random(in: -0.029...0.019)

        let startpos = SCNAction.move(by: SCNVector3(0, 0.028, 0), duration: 0)
        let moveDown = SCNAction.move(by: SCNVector3(.random(in: -0.029...0.009) + xDelta, -0.028, 0 + zDelta), duration: 0.22)
        let moveUp = SCNAction.move(by: SCNVector3(0, 0.011, 0), duration: 0.13)
        let fall = SCNAction.move(by: SCNVector3(0, -0.011, 0), duration: 0.08)
        //let waitAction = SCNAction.wait(duration: 0.25)
        let hoverSequence = SCNAction.sequence([startpos, moveDown, moveUp, fall])
        let loopSequence = SCNAction.repeat(hoverSequence, count: 1) //.repeatForever(hoverSequence)
        
        dice.runAction(loopSequence)
        dice.removeAllAnimations()
        
        dice.physicsBody?.isAffectedByGravity = false

    }
    
    @IBAction func clearAll(_ sender: UIBarButtonItem) {
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
    
    @IBAction func newRoll(_ sender: UIBarButtonItem) {
        rollAllCu()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAllCu()
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor{
            
            print("plane detected")
            let planeAnchor = anchor as! ARPlaneAnchor
            
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z)) // not Y !
            
            let planeNode = SCNNode()
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grd.png")
            plane.materials = [gridMaterial]
            
            planeNode.geometry = plane
            
            //node.addChildNode(planeNode) // пригодная поверхность)
            
        }else{
            return
        }
    }
}
