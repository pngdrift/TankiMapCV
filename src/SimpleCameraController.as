/*
Copyright 2025 pngdrift
SPDX-License-Identifier: Apache-2.0
*/
package {

    import org.apache.royale.events.KeyboardEvent;
    import org.apache.royale.events.MouseEvent;

    public class SimpleCameraController {

        private var keys:Object = {};
        private var camera:*;
        private var mouseActive:Boolean;
        private var lastMouseX:Number = 0;
        private var lastMouseY:Number = 0;

        public function SimpleCameraController(camera:*) {
            this.camera = camera;
            window.addEventListener(KeyboardEvent.KEY_DOWN,function(event:KeyboardEvent):void {
                    keys[event.code] = true;
                });
            window.addEventListener(KeyboardEvent.KEY_UP,function(event:KeyboardEvent):void {
                    delete keys[event.code];
                });
            window.addEventListener(MouseEvent.MOUSE_DOWN,function(event:MouseEvent):void {
                    mouseActive = true;
                    lastMouseX = event.clientX;
                    lastMouseY = event.clientY;
                });
            window.addEventListener(MouseEvent.MOUSE_UP,function(event:MouseEvent):void {
                    mouseActive = false;
                });
            window.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
        }

        private var mouseSensitivity:Number = 0.004;

        private function onMouseMove(event:MouseEvent):void {
            if(!mouseActive) {
                return;
            }
            var deltaX:Number = event.clientX - lastMouseX;
            var deltaY:Number = event.clientY - lastMouseY;
            lastMouseX = event.clientX;
            lastMouseY = event.clientY;
            euler["setFromQuaternion"](camera["quaternion"]);
            euler.y -= deltaX * mouseSensitivity;
            euler.x -= deltaY * mouseSensitivity;
            euler.x = Math.max(-pitchLimit,Math.min(pitchLimit,euler.x));
            camera["quaternion"]["setFromEuler"](euler);
        }

        private static const movementSpeed:Number = 3000;
        private static const rotationSpeed:Number = 2;
        private static const pitchLimit:Number = Math.PI / 2;
        private static const speedMultiplier:Number = 2;

        private var euler:* = new THREE.Euler(0,0,0,"YXZ");

        public function updateCamera(dt:Number):void {
            var speed:Number = movementSpeed * dt;
            var rotSpeed:Number = rotationSpeed * dt;
            if(keys["ShiftLeft"] || keys["ShiftRight"]) {
                speed *= speedMultiplier;
            }

            var direction:* = new THREE.Vector3();
            camera["getWorldDirection"](direction);

            if(keys["KeyW"]) {
                camera.position.add(direction.clone()["multiplyScalar"](speed));
            }
            if(keys["KeyS"]) {
                camera.position.add(direction.clone()["multiplyScalar"](-speed));
            }

            var right:* = direction.clone();
            right.cross(new THREE.Vector3(0,1,0)).normalize();
            if(keys["KeyA"]) {
                camera.position.add(right.clone()["multiplyScalar"](-speed));
            }
            if(keys["KeyD"]) {
                camera.position.add(right.clone()["multiplyScalar"](speed));
            }

            var up:* = direction.clone();
            up.cross(new THREE.Vector3(0,0,1)).normalize();
            if(keys["KeyQ"]) {
                camera.position.y -= speed;
            }
            if(keys["KeyE"]) {
                camera.position.y += speed;
            }

            euler["setFromQuaternion"](camera["quaternion"]);

            if(keys["ArrowLeft"]) {
                euler.y += rotSpeed;
            }
            if(keys["ArrowRight"]) {
                euler.y -= rotSpeed;
            }

            if(keys["ArrowUp"]) {
                euler.x += rotSpeed;
            }
            if(keys["ArrowDown"]) {
                euler.x -= rotSpeed;
            }
            euler.x = Math.max(-pitchLimit,Math.min(pitchLimit,euler.x));

            camera["quaternion"]["setFromEuler"](euler);
        }
    }
}