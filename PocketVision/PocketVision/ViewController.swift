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

// vector distancing adjust based on https://github.com/NovatecConsulting/FaceRecognition-in-ARKit/blob/master/faceIT/SCNVector3%2BDistance.swift
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

//ARSCNView Code based on https://stackoverflow.com/questions/51070395/distance-between-face-and-camera-using-arkit
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
        guard let faceAnchor = anchor as? ARFaceAnchor else{ return}
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
            let faceDistanceFromCamera = self.faceNode.worldPosition - SCNVector3Zero
            let leftEyeDistanceFromCamera = self.leftEye.worldPosition - SCNVector3Zero
            let rightEyeDistanceFromCamera = self.rightEye.worldPosition - SCNVector3Zero
          //  var averageDistance = (leftEyeDistanceFromCamera.length + rightEyeDistanceFromCamera.length) / 2
          //  let averageDistanceCM = (Int(round(averageDistance * 100)))
            let faceDistanceCM = (Int(round(faceDistanceFromCamera.length * 100)))
            let leftEyeDistanceCM = (Int(round(leftEyeDistanceFromCamera.length * 100)))
            let rightEyeDistanceCM = (Int(round(rightEyeDistanceFromCamera.length * 100)))
            
            if (self.whichEye == "right"){
                self.distance = CGFloat(rightEyeDistanceCM)
                self.distanceLabel.text = String(rightEyeDistanceCM)
            }else if (self.whichEye == "left"){
                self.distance = CGFloat(leftEyeDistanceCM)
                self.distanceLabel.text = String(leftEyeDistanceCM)
            }else{
                self.distance = CGFloat(faceDistanceCM)
                self.distanceLabel.text = String(faceDistanceCM)
            }
          //  print("Approximate Distance Of Face From Camera = \(averageDistanceCM)")
        }
    }
}

class ViewController: UIViewController{
    @IBOutlet weak var distanceLabel: UILabel!
  //  @IBOutlet var sceneView:ARSCNView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var chartLabel: UILabel!
    @IBOutlet weak var startTestImage: UIImageView!
    @IBOutlet weak var viewCover: UIView!
    @IBOutlet weak var startView: UIView!
    @IBOutlet weak var startImage: UITapGestureRecognizer!
    @IBOutlet weak var warningImage: UIImageView!
    
    @IBOutlet weak var leftEyeButton: UIButton!
    @IBOutlet weak var rightEyeButton: UIButton!
    
    @IBOutlet weak var dialogueBoxImage: UIImageView!
    
    var faceNode = SCNNode()
    var leftEye = SCNNode()
    var rightEye = SCNNode()
    var updateTimer : Timer?;
    var distance = CGFloat(25.0)
    var setDistance = 40
    var upperBoundDistance = 43
    var lowerBoundDistance = 37
    var isTestFinished = false
    var isTestStart = false
    var whichEye = "Unknown"
    var choosedDirection:Int = 4
    let startAcuity = 2
    var acuity = 2
    //-----------------------
    // MARK: - View LifeCycle
    //-----------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        chartLabel.isHidden = true
        
        startTestImage.image = UIImage(named: "startTest")
        startTestImage.isUserInteractionEnabled = true
        leftEyeButton.layer.cornerRadius = CGFloat(25)
        rightEyeButton.layer.cornerRadius = CGFloat(25)
        
        warningImage.image = UIImage(named: "warningPhone")
        dialogueBoxImage.image = UIImage(named:"dialogueBox")
        //1. Set Up Face Tracking
        guard ARFaceTrackingConfiguration.isSupported else {
            print("not supported")
            return }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        viewCover.isHidden = true
        
      //  sceneView.showsStatistics = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.delegate = self
        
        setupEyeNode()
        
        updateTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self,
            selector: #selector(self.updateDistanceLabel),
            userInfo: nil,
            repeats: true)
        
        //swipe gesture recognition
        
    }
    @IBAction func didSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        print("left")
        choosedDirection = 0
    }
    
    @IBAction func didSwipeRight(_ sender: UISwipeGestureRecognizer) {
        print("right")
        choosedDirection = 1
    }
    
    @IBAction func didSwipeDown(_ sender: UISwipeGestureRecognizer) {
        print("down")
        choosedDirection = 2
    }
    
    @IBAction func didSwipeUp(_ sender: UISwipeGestureRecognizer) {
        print("up")
        choosedDirection = 3
    }
    
    @IBAction func leftPressed(_ sender: UIButton) {
        whichEye = "left"
        rightEye.isHidden = false
        leftEye.isHidden = true
    }
    
    @IBAction func rightPressed(_ sender: UIButton) {
        whichEye = "right"
        rightEye.isHidden = true
        leftEye.isHidden = false
    }
    
    @IBAction func startImagePressed(_ sender: UITapGestureRecognizer) {
        if (whichEye != "Unknown"){
           print("startPressed")
           startView.isHidden = true
           self.isTestStart = true

        }else{
            print("should select which eye to test")}
    }
    
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated) }
    //-----------------------
    // MARK: - Eye Node Setup
    //-----------------------
    /// Creates To SCNSpheres To Loosely Represent The Eyes
    func setupEyeNode(){
        
        //1. Create A Node To Represent The Eye
        let eyeGeometry = SCNSphere(radius: 0.007)
        eyeGeometry.materials.first?.diffuse.contents = UIColor.white
        eyeGeometry.materials.first?.transparency = 1
        //2. Create A Holder Node & Rotate It So The Gemoetry Points Towards The Device
        let node = SCNNode()
        node.geometry = eyeGeometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        node.opacity = 0.4
        leftEye = node.clone()
        rightEye = node.clone()
    }

    func eyeTest()->Int{
        var temp = false
        isTestFinished = true
        return 0
    }
    
    func testRound(level:Int)->Bool{
        var result = false
        let displayDirection = Int.random(in: 0...3)
        // ImageName = displayDirection+level
        //image =UIImage(named:ImageName)
        
        //wait for user response
        
        if displayDirection == choosedDirection{
            result = true}
        return result
    }
    
    @objc
    func updateDistanceLabel()
    {
        if isTestStart{
            chartLabel.isHidden = false
            chartLabel.font = .systemFont(ofSize: self.distance)
            if (Int(self.distance) > self.upperBoundDistance)
            {
                viewCover.isHidden = false
            }else if (Int(self.distance) < self.lowerBoundDistance)
            {
                viewCover.isHidden = false
            }else{
                viewCover.isHidden = true
        }
    }
    }
}

