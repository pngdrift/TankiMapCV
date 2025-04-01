/*
Copyright 2025 pngdrift
SPDX-License-Identifier: Apache-2.0
*/
package {
    import alternativa.physics.collision.CollisionKdNode;
    import alternativa.physics.collision.types.BoundBox;

    public class KdNodesVisualization {

        private var nodes:Vector.<CollisionKdNode> = new <CollisionKdNode>[];

        public static var group:*;

        private var maxIndicesInNode:int;

        public function setRootNode(rootNode:CollisionKdNode):void {
            if(group as THREE.Group) {
                this.clearGroup();
                maxIndicesInNode = 0;
            }
            group = new THREE.Group();
            collectNode(rootNode);
            TankiMapCV.instance.maxIndicesLabel.text = "Max indices in node: " + maxIndicesInNode;
            addNodesToScene();
        }

        private function collectNode(node:CollisionKdNode):void {
            if(node == null) {
                return;
            }
            if(node.indices != null) {
                nodes.push(node);
                maxIndicesInNode = Math.max(maxIndicesInNode,node.indices.length);
            }
            collectNode(node.negativeNode);
            collectNode(node.positiveNode);
        }

        private function addNodesToScene():void {
            for each(var node:CollisionKdNode in nodes) {
                var aabb:BoundBox = node.boundBox;
                var margin:int = 0;
                var minX:Number = aabb.minX - margin;
                var minY:Number = aabb.minY - margin;
                var minZ:Number = aabb.minZ - margin;
                var maxX:Number = aabb.maxX + margin;
                var maxY:Number = aabb.maxY + margin;
                var maxZ:Number = aabb.maxZ + margin;
                var sizeX:Number = maxX - minX;
                var sizeY:Number = maxY - minY;
                var sizeZ:Number = maxZ - minZ;
                var material:* = new THREE.MeshPhongMaterial({
                            "color": getColor(node.indices.length),
                            "transparent": true,
                            "opacity": Math.min(0.7,node.indices.length / 200) + 0.1,
                            "emissive": new THREE.Color()["setHex"](0)
                        });
                var box:* = new THREE.Mesh(new THREE.BoxGeometry(sizeX,sizeZ,sizeY),material);
                box.indices = node.indices.length;
                box.position.set (-(minX + (sizeX / 2)),minZ + (sizeZ / 2),minY + (sizeY / 2));
                group.add(box);
            }
            MapView.scene.add(group);
        }

        private function getColor(value:Number):uint {
            value = Math.max(0,Math.min(200,value));
            var ratio:Number = value / 200;
            var red:uint = Math.round(255 * ratio);
            var green:uint = Math.round(255 * (1 - ratio));
            return (red << 16) | (green << 8);
        }

        public function set visible(value:Boolean):void {
            if(group)
                group.visible = value;
        }

        private function clearGroup():void {
            while(group.children.length > 0) {
                group.remove(group.children[0]);
            }
            group["removeFromParent"]();
            nodes.length = 0;
        }
    }
}