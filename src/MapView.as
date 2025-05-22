/*
Copyright 2025 pngdrift
SPDX-License-Identifier: Apache-2.0
*/
package {
	import org.apache.royale.html.Label;
	import org.apache.royale.events.MouseEvent;
	import org.apache.royale.events.Event;

	public class MapView {

		public static var scene:*;
		public static var camera:*;

		public static var inited:Boolean;

		public static function initScene():void {
			if(inited) {
				return;
			}
			inited = true;
			scene = new THREE.Scene();

			var skyLoader:* = new THREE.CubeTextureLoader();
			skyLoader.setPath("https://raw.githubusercontent.com/terminal-cs/TO-assets/main/Battle/skyboxes/skybox18/");
			scene.background = skyLoader.load([
						"01.jpg","03.jpg",
						"05.jpg","06.jpg",
						"04.jpg","02.jpg",
					]);

			camera = new THREE.PerspectiveCamera(75,window.innerWidth / window.innerHeight,1,120000);

			scene.add(new THREE.AmbientLight(0xffffff,0.6));
			var dirLight:* = new THREE.DirectionalLight(0xffffff,0.9);
			dirLight.position.set (1,0.5,0);
			scene.add(dirLight);

			var renderer:* = new THREE.WebGLRenderer();
			renderer.setSize(window.innerWidth,window.innerHeight);
			document.body.appendChild(renderer.domElement);

			window.addEventListener(Event.RESIZE,function():void {
					camera.aspect = window.innerWidth / window.innerHeight;
					camera.updateProjectionMatrix();
					renderer.setSize(window.innerWidth,window.innerHeight);
				},false);

			var cameraController:SimpleCameraController = new SimpleCameraController(camera);

			var cameraPosLabel:Label = TankiMapCV.instance.cameraPosLabel;
			function updateCameraPosLabel(x:int,y:int,z:int):void {
				cameraPosLabel.text = "Camera pos by x: " + x + " y: " + y + " z: " + z;
			}

			var raycaster:* = new THREE.Raycaster(),
				pointer:* = new THREE.Vector2(),
				intersectedNode:*;
			window.addEventListener(MouseEvent.MOUSE_MOVE,function(event:*):void {
					pointer.x = (event.clientX / window.innerWidth) * 2 - 1;
					pointer.y = -(event.clientY / window.innerHeight) * 2 + 1;
				});
			var selectedNodeIndicesLabel:Label = TankiMapCV.instance.selectedNodeIndicesLabel;
			function updateSelectedNodeIndicesLabel(count:int):void {
				selectedNodeIndicesLabel.text = "Indices count in selected node: " + (count ? count : "");
			}

			var clock:* = new THREE.Clock();
			var previousTime:Number = 0;
			renderer.setAnimationLoop(function():void {
					var elapsedTime:Number = clock.getElapsedTime();
					var deltaTime:Number = elapsedTime - previousTime;
					previousTime = elapsedTime;

					raycaster.setFromCamera(pointer,camera);

					var kdNodesGroup:* = KdNodesVisualization.group;
					if(kdNodesGroup && kdNodesGroup.children) {
						var intersects:Array = raycaster.intersectObjects(kdNodesGroup.children,false)
							.filter(function(intersection:*):Boolean {
									return intersection.object.visible;
								});
						if(intersects.length > 0) {
							if(intersectedNode != intersects[0].object) {
								if(intersectedNode) {
									intersectedNode.material.opacity = intersectedNode.currentOpacity;
									intersectedNode.material.emissive.setHex(0);
								}
								intersectedNode = intersects[0].object;
								intersectedNode.currentOpacity = intersectedNode.material.opacity;
								intersectedNode.material.opacity += 0.1;
								intersectedNode.material.emissive.setHex(0x111111);
								updateSelectedNodeIndicesLabel(intersectedNode.indices);
							}
						}
						else if(intersectedNode) {
							intersectedNode.material.opacity = intersectedNode.currentOpacity;
							intersectedNode.material.emissive.setHex(0);
							intersectedNode = null;
							updateSelectedNodeIndicesLabel(0);
						}
					}

					renderer.render(scene,camera);
					cameraController.updateCamera(deltaTime);
					updateCameraPosLabel(-camera.position.x,camera.position.z,camera.position.y);
				});
		}
	}
}