//
//  ViewController.swift
//  PocketVision
//
//  Created by 安浩一 on 12/8/20.
//

import UIKit
import SceneKit
import Foundation
import ARKit
//------------------------------
// MARK: - SCNVector3 Extensions
//------------------------------

extension SCNVector3 {
    var length:Float {
        get {
            return sqrtf(x*x + y*y + z*z)
        }
    }
    func distance(toVector: SCNVector3) -> Float {
        return (self - toVector).length
    }
    
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
    }

    static func center(_ vectors: [SCNVector3]) -> SCNVector3 {
        var x: Float = 0
        var y: Float = 0
        var z: Float = 0
        
        let size = Float(vectors.count)
        vectors.forEach {
            x += $0.x
            y += $0.y
            z += $0.z
        }
        return SCNVector3Make(x / size, y / size, z / size)
    }
}

//--------------------------
// MARK: - ARSCNViewDelegate
//--------------------------

extension ViewController: ARSCNViewDelegate{

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //1. Setup The FaceNode & Add The Eyes
        faceNode = node
        faceNode.addChildNode(leftEye)
        faceNode.addChildNode(rightEye)
        faceNode.transform = node.transform
        //2. Get The Distance Of The Eyes From The Camera
        trackDistance()
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        faceNode.transform = node.transform
        //2. Check We Have A Valid ARFaceAnchor
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        //3. Update The Transform Of The Left & Right Eyes From The Anchor Transform
        leftEye.simdTransform = faceAnchor.leftEyeTransform
        rightEye.simdTransform = faceAnchor.rightEyeTransform
        //4. Get The Distance Of The Eyes From The Camera
        trackDistance()
    }
    /// Tracks The Distance Of The Eyes From The Camera
    func trackDistance(){
        DispatchQueue.main.async {
            //4. Get The Distance Of The Eyes From The Camera
            let leftEyeDistanceFromCamera = self.leftEye.worldPosition - SCNVector3Zero
            let rightEyeDistanceFromCamera = self.rightEye.worldPosition - SCNVector3Zero

            //5. Calculate The Average Distance Of The Eyes To The Camera
            let averageDistance = (leftEyeDistanceFromCamera.length + rightEyeDistanceFromCamera.length) / 2
            let averageDistanceCM = (Int(round(averageDistance * 100)))
            self.distanceLabel.text = String(averageDistanceCM)
            print("Approximate Distance Of Face From Camera = \(averageDistanceCM)")
        }
    }
}

class ViewController: UIViewController{

    
    @IBOutlet weak var distanceLabel: UILabel!
  //  @IBOutlet var sceneView:ARSCNView!
    @IBOutlet var sceneView: ARSCNView!
    
    var faceNode = SCNNode()
    var leftEye = SCNNode()
    var rightEye = SCNNode()

    //-----------------------
    // MARK: - View LifeCycle
    //-----------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        //1. Set Up Face Tracking
        guard ARFaceTrackingConfiguration.isSupported else {
            print("not supported")
            return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        sceneView.showsStatistics = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.delegate = self
        //2. Setup The Eye Nodes
        setupEyeNode()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated) }

    //-----------------------
    // MARK: - Eye Node Setup
    //-----------------------

    /// Creates To SCNSpheres To Loosely Represent The Eyes
    func setupEyeNode(){
        //1. Create A Node To Represent The Eye
        let eyeGeometry = SCNSphere(radius: 0.005)
        eyeGeometry.materials.first?.diffuse.contents = UIColor.cyan
        eyeGeometry.materials.first?.transparency = 1
        //2. Create A Holder Node & Rotate It So The Gemoetry Points Towards The Device
        let node = SCNNode()
        node.geometry = eyeGeometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        //3. Create The Left & Right Eyes
        leftEye = node.clone()
        rightEye = node.clone()
    }

}

