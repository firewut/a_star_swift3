import Foundation
import SceneKit

var node_chance_to_be_wall = 10

var node_width: CGFloat = 10,
node_height: CGFloat = 10,
node_lenght: CGFloat = 10,
node_chamferRadius: CGFloat = 0,
node_spacing: CGFloat = 5

class Node: Comparable {
    var Y: Int = 0,
        X: Int = 0,
        Z: Int = 0
    
    
    var Neighbors: [Node] = []
    
    var is_wall: Bool = false
    var is_start: Bool = false
    var is_end: Bool = false
    var is_path_item: Bool = false
    var is_in_open_set: Bool = false
    
    var f: Int = 0
    var g: Int = 0
    var h: Float = 0.0
    
    var previous: Node?
    
    var scn_node: SCNNode?
    
    init(x: Int, y: Int, z: Int) {
        self.X = x
        self.Y = y
        self.Z = z
        
        self.is_wall = Int.random(range: 0..<100) < node_chance_to_be_wall
    }
    
    func reset(){
        self.f = 0
        self.g = 0
        self.h = 0
        self.previous = nil
    }
    
    static func < (lhs: Node, rhs: Node) -> Bool {
        return lhs.description() < rhs.description()
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.description() == rhs.description()
    }
    
    func description() -> String {
        return "\(self.Y)-\(self.X)-\(self.Z)"
    }
    
    func get_geometry() -> SCNGeometry {
        let _node_spacing = node_width/node_spacing
        
        return SCNBox(
            width: node_width - _node_spacing,
            height: node_height - _node_spacing,
            length: node_lenght - _node_spacing,
            chamferRadius: node_chamferRadius
        )
    }
    
    func set_geometry_materials() {
        if let scn_node = self.scn_node {
            if let geometry = scn_node.geometry {
                geometry.materials.first?.transparency = 1
                 if self.is_start || self.is_end {
                    geometry.materials.first?.diffuse.contents = UIColor.red
                } else if self.is_path_item {
                    geometry.materials.first?.diffuse.contents = UIColor.orange
                } else if self.is_wall {
                    geometry.materials.first?.diffuse.contents = UIColor.gray
                } else {
                    geometry.materials.first?.diffuse.contents = UIColor.clear
//                    geometry.materials.first?.transparency = 0.2
                }
            }
        }
    }
    
    func set_scn_node(_ _scn_node: SCNNode) {
        self.scn_node = _scn_node
    }
    
    func get_scn_node() -> SCNNode {
        let scn_node = SCNNode()
        
        scn_node.name = self.description()
        scn_node.geometry = self.get_geometry()
        self.set_geometry_materials()
        
        scn_node.physicsBody = SCNPhysicsBody(
            type: SCNPhysicsBodyType.static,
            shape: nil
        )
        
        return scn_node
    }
}

class _Grid {
    var Rows: Int = 0,
        Columns: Int = 0,
        Depth: Int = 0
    
    var Nodes: [Node] = []
    
    var Start: Node?
    var End: Node?
    
    private var open_set: [Node] = []
    private var closed_set: [Node] = []

    
    var path: [Node] = []
    
    init(_ rows: Int, _ columns: Int, _ depth: Int) {
        self.Rows = rows
        self.Columns = columns
        self.Depth = depth
        
        self.path = []
        self.Nodes = []
        
        self.open_set = []
        self.closed_set = []
        
        if rows == 0 || columns == 0 {
            return
        }
        
        // Chose start and end nodes
        let random_start_x = Int.random(range: 0..<columns)
        let random_start_z = Int.random(range: 0..<depth)
        let random_end_x = Int.random(range: 0..<columns)
        let random_end_z = Int.random(range: 0..<depth)
        
        // Append new nodes
        for row in 0..<rows {
            for column in 0..<columns {
                for _depth in 0..<depth {
                    let node = Node(
                        x: column,
                        y: row,
                        z: _depth)
                    self.Nodes.append(
                        node
                    )
                    if row == 0 &&
                        column == random_start_x &&
                        _depth == random_start_z {
                        _ = self._setStart(node)
                    }
                    if row == rows - 1 &&
                        column == random_end_x &&
                        _depth == random_end_z {
                        _ = self._setEnd(node)
                    }
                }
            }
        }
        
        // Set the entrypoint
        if let start = self.Start {
            self.open_set.append(start)
        }
        
        // Mark siblings
        for node in self.Nodes {
            node.Neighbors = self.get_node_neighbors(node: node)
        }
    }
    
    func get_node_neighbors(node: Node) -> [Node] {
        var neighbors: [Node] = []
        
        // O(3^n)
        for _node in self.Nodes {
            if _node != node {
                if (node.X-1...node.X+1).contains(_node.X) {
                    if (node.Y-1...node.Y+1).contains(_node.Y) {
                        if (node.Z-1...node.Z+1).contains(_node.Z) {
                            neighbors.append(
                                _node
                            )
                        }
                    }
                }
            }
        }
        return neighbors
    }
    
    func distance(_ a: Node, _ b: Node) -> Float {
        let d = sqrt(
            Float(
                pow(Float(a.X - b.X), 2)
            ) +
            Float(
                pow(Float(a.Y - a.Y), 2)
            ) +
            Float(
                pow(Float(a.Z - a.Z), 2)
            )
        )
        
        return d
    }
    
    func heuristic(_ a: Node, _ b: Node) -> Float {
        return self.distance(a, b)
    }
    
    
    func Calculate(){
        var has_solution: Bool = true
        
        self.open_set = []
        self.closed_set = []
        
        self.open_set.append(self.Start!)
        self.path = []
        
        for node in self.Nodes {
            node.reset()
        }
        
        while has_solution {
            if self.open_set.count > 0 {
                self.path = []
                
                
                var lowest_index = 0
                for i in 0..<self.open_set.count {
                    if(self.open_set[i].f < self.open_set[lowest_index].f){
                        lowest_index = i
                    }
                }
                
                
                // Get lowest `f` Node in a set
                let current: Node = self.open_set[lowest_index]
                
                
                // Add to `path`
                var tmp: Node = current
                self.path.append(tmp)
                while (tmp.previous != nil) {
                    tmp = tmp.previous!
                    self.path.append(tmp)
                }
                
                // If we reached the end
                if current == self.End! {
                    break
                }
                
                // Remove current from open_set
                self.open_set.remove(at: lowest_index)
                self.closed_set.append(current)
                
                for neighbor in current.Neighbors {
                    if neighbor.is_wall {
                        self.closed_set.append(neighbor)
                    }
                    
                    if self.closed_set.contains(neighbor){
                        continue
                    }
                    
                    let temporary_g: Int = current.g + 1
                    var closer_neighbor_found: Bool = false
                    
                    if self.open_set.contains(neighbor){
                        if temporary_g < neighbor.g {
                            closer_neighbor_found = true
                            
                            neighbor.g = temporary_g
                        }
                    } else {
                        closer_neighbor_found = true
                        neighbor.g = temporary_g
                        self.open_set.append(neighbor)
                    }
                    
                    if closer_neighbor_found {
                        neighbor.h = self.heuristic(neighbor, self.End!)
                        neighbor.f = neighbor.f + neighbor.g
                        neighbor.previous = current
                    }
                }
            } else {//
                has_solution = false
                NSLog("Grid has No solution")
            }
        }
        
        // Prepare nodes with materials
        for node in self.Nodes {
            if self.path.contains(node) {
                node.is_path_item = true
            }else{
                node.is_path_item = false
            }
            if self.open_set.contains(node){
                node.is_in_open_set = true
            }else{
                node.is_in_open_set = false
            }
            
            if node.scn_node == nil {
                let _scn_node = node.get_scn_node()
                _scn_node.position = SCNVector3Make(
                    Float(CGFloat(node.X) * node_width),
                    Float(CGFloat(self.Rows - node.Y) * node_height),
                    Float(CGFloat(self.Depth - node.Z) * node_lenght)
                )
                node.set_scn_node(_scn_node)
            }
        }
    }
    
    func checkSCNNodeIsNode(scn_node: SCNNode) -> Node? {
        for node in self.Nodes {
            if let _scn_node = node.scn_node {
                if _scn_node == scn_node {
                    return node
                }
            }
        }
        
        return nil
    }
    
    private func _setStart(_ node: Node){
        self.Start = node
        node.is_start = true
        self.open_set.removeAll()
        self.open_set.append(node)
    }
    
    private func _setEnd(_ node: Node){
        self.End = node
        node.is_end = true
    }
    
    func setStart(_ node: Node) -> Bool {
        if self.Nodes.contains(node){
            if let tmp_end = self.End {
                if node == tmp_end {
                    return false
                }
            }
            if let tmp_start = self.Start {
                if tmp_start == node {
                    return true
                }
                tmp_start.is_start = false
            }
            self._setStart(node)
            
            return true
        }
        
        return false
    }
    
    func setEnd(_ node: Node) -> Bool{
        if self.Nodes.contains(node){
            if let tmp_start = self.Start {
                if tmp_start == node {
                    return false
                }
            }
            if let tmp_end = self.End {
                if tmp_end == node {
                    return true
                }
                tmp_end.is_end = false
            }
            self._setEnd(node)
            
            return true
        }
        
        return false
    }
    
    var toggleEndpoint: Bool = true;
    func SetEndpointNode(node: Node) -> Bool {
        if toggleEndpoint {
            if !self.setStart(node) {
                NSLog("Cannot set start equal to end")
                return false
            }
        }else{
            if !self.setEnd(node) {
                NSLog("Cannot set start equal to end")
                return false
            }
        }
        self.toggleEndpoint = !self.toggleEndpoint
        
        return true
    }
    
    func Draw(scene: SCNScene){
        for node in self.Nodes {
            // Check if `scene` does not contain this node
            let existing_node = scene.rootNode.childNode(
                withName: node.description(),
                recursively: false
            )
            if existing_node == nil {
                if let _scn_node = node.scn_node {
                    scene.rootNode.addChildNode(
                        _scn_node
                    )
                }
            }else{
                node.set_geometry_materials()
            }
        }
    }
}
