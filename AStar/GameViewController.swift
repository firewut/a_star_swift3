//
//  GameViewController.swift
//  AStar
//
//  Created by Andrew on 13.08.17.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    
    var rows: Int = 20,
        cols: Int = 20
    
    var gridView: SCNView!,
        gridScene: SCNScene!
//        cameraNode: SCNNode!
    
    var grid = _Grid(0,0)
    
    func initView(){
        self.gridView = self.view as! SCNView
        self.gridView.allowsCameraControl = true
        self.gridView.autoenablesDefaultLighting = true
        
        self.gridView.delegate = self
    }
    
    func initScene(){
        self.gridScene = SCNScene()
        self.gridView.scene = self.gridScene
        
        self.gridView.isPlaying = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.grid = _Grid(rows, cols)

        self.initView()
        self.initScene()
        self.grid.Calculate()
    }
    
    var render_interval: TimeInterval = 0;
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if time > self.render_interval {
            self.render_interval = time + 0.1
            self.grid.Draw(
                scene: self.gridScene
            )
        }
    }
    
    var touches_moved: Bool = false
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touches_moved = true
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 && !self.touches_moved {
            let touch = touches.first
            
            let location = touch?.location(in: self.gridView)
            
            if location != nil {
                let hitList = self.gridView.hitTest(location!, options: nil)
                if let hitObject = hitList.first {
                    let node = hitObject.node
                    if let grid_node = self.grid.checkSCNNodeIsNode(scn_node: node) {
                        if self.grid.SetEndpointNode(node: grid_node) {
                            self.grid.Calculate()
                        }
                    }
                }
            }
        }
        self.touches_moved = false
        super.touchesEnded(touches, with: event)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
