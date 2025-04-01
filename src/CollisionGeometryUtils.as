/*
Copyright 2025 pngdrift
SPDX-License-Identifier: Apache-2.0
*/
package {
  import alternativa.math.*;
  import alternativa.physics.collision.CollisionShape;
  import alternativa.physics.collision.primitives.*;
  import alternativa.physics.PhysicsMaterial;

  public class CollisionGeometryUtils {

    private static const COLLISION_PLANE:String = "collision-plane";
    private static const COLLISION_BOX:String = "collision-box";
    private static const COLLISION_TRIANGLE:String = "collision-triangle";

    public static function parseAndAdd(mapXml:XML):Vector.<CollisionShape> {
      initMaterials();
      var collisionPrimitives:Vector.<CollisionShape> = new <CollisionShape>[];
      var collisionPrimitive:CollisionShape;
      for each(collisionPrimitive in parseCollisionGeometry(mapXml,COLLISION_PLANE)) {
        collisionPrimitives.push(collisionPrimitive);
      }
      for each(collisionPrimitive in parseCollisionGeometry(mapXml,COLLISION_BOX)) {
        collisionPrimitives.push(collisionPrimitive);
      }
      for each(collisionPrimitive in parseCollisionGeometry(mapXml,COLLISION_TRIANGLE)) {
        collisionPrimitives.push(collisionPrimitive);
      }
      return collisionPrimitives;
    }

    private static const halfSize:Vector3 = new Vector3();

    private static function parseCollisionGeometry(mapXml:XML,collisionType:String):Vector.<CollisionShape> {
      var instancedMeshes:Object = {};
      var collisionPrimitives:Vector.<CollisionShape> = new Vector.<CollisionShape>();
      var collisionElements:XMLList = mapXml.elements("collision-geometry")[0].elements(collisionType);
      for each(var collisionElement:XML in collisionElements) {
        var primitive:CollisionShape;
        var key:String;
        switch(collisionType) {
          case COLLISION_PLANE:
            var width:Number = collisionElement.width;
            var length:Number = collisionElement.length;
            halfSize.x = 0.5 * width;
            halfSize.y = 0.5 * length;
            halfSize.z = 0;
            primitive = new CollisionRect(halfSize,0xff,PhysicsMaterial.DEFAULT_MATERIAL);
            key = width + "x" + length;
            break;
          case COLLISION_BOX:
            readVector3(collisionElement.size,halfSize);
            halfSize.scale(0.5);
            primitive = new CollisionBox(halfSize,0xff,PhysicsMaterial.DEFAULT_MATERIAL);
            key = halfSize.toString();
            break;
          case COLLISION_TRIANGLE:
            var v0:Vector3 = new Vector3(),
              v1:Vector3 = new Vector3(),
              v2:Vector3 = new Vector3();
            readVector3(collisionElement.v0,v0);
            readVector3(collisionElement.v1,v1);
            readVector3(collisionElement.v2,v2);
            primitive = new CollisionTriangle(v0,v1,v2,0xff,PhysicsMaterial.DEFAULT_MATERIAL);
            key = v0.toString() + v1.toString() + v2.toString();
            break;
        }
        setCollisionShapeOrientation(primitive,collisionElement);
        collisionPrimitives.push(primitive);
        if(!instancedMeshes[key]) {
          var geometry:*,material:*;
          switch(collisionType) {
            case COLLISION_PLANE:
              geometry = new THREE.PlaneGeometry(width,length);
              material = planeMaterial;
              break;
            case COLLISION_BOX:
              geometry = new THREE.BoxGeometry(halfSize.x * 2,halfSize.y * 2,halfSize.z * 2);
              material = boxMaterial;
              break;
            case COLLISION_TRIANGLE:
              geometry = new THREE.BufferGeometry();
              geometry["setFromPoints"]([
                    new THREE.Vector3(-v0.x,v0.z,v0.y),
                    new THREE.Vector3(-v1.x,v1.z,v1.y),
                    new THREE.Vector3(-v2.x,v2.z,v2.y),
                  ]);
              geometry["setAttribute"]("uv",new THREE.BufferAttribute(new Float32Array([0,0,1,0,0,1]),2));
              geometry["computeVertexNormals"]();
              material = triangleMaterial;
              break;
          }
          instancedMeshes[key] = {
              mesh: new THREE.InstancedMesh(geometry,material,collisionElements.length()),
              count: 0
            };
        }
        var instanceData:* = instancedMeshes[key];
        setupCollisionInInstance(instanceData.mesh,instanceData.count++,collisionType != COLLISION_TRIANGLE);
      }
      for each(var data:* in instancedMeshes) {
        data.mesh.count = data.count;
        data.mesh.name = collisionType;
        MapView.scene.add(data.mesh);
      }
      return collisionPrimitives;
    }

    private static const position:Vector3 = new Vector3();
    private static const rotation:Vector3 = new Vector3();
    private static const rotationMatrix:Matrix3 = new Matrix3();

    private static function setCollisionShapeOrientation(primitive:CollisionShape,collisionElement:XML):void {
      readVector3(collisionElement.position,position);
      readVector3(collisionElement.rotation,rotation);
      rotationMatrix.setRotationMatrix(rotation.x,rotation.y,rotation.z);
      primitive.transform.setFromMatrix3(rotationMatrix,position);
    }

    private static function readVector3(xml:XMLList,result:Vector3):void {
      var element:XML = xml[0];
      result.x = element.x;
      result.y = element.y;
      result.z = element.z;
    }

    private static function setupCollisionInInstance(instanceMesh:*,index:int,needRotate:Boolean = true):void {
      var dummy:* = new THREE.Object3D();
      dummy.position.x = -position.x;
      dummy.position.y = position.z;
      dummy.position.z = position.y;
      dummy.rotation.copy(new THREE.Euler(-rotation.x,rotation.z,rotation.y,"YZX"));
      if(needRotate) {
        dummy["rotateX"](-Math.PI / 2);
      }
      dummy["updateMatrix"]();
      instanceMesh["setMatrixAt"](index,dummy.matrix);
    }

    private static var planeMaterial:*;
    private static var boxMaterial:*;
    private static var triangleMaterial:*;

    private static var grayMaterial:*;
    private static var grayTriangleMaterial:*;

    private static const TEXTURE_SIZE:int = 256;
    private static const BOX_COLOR:String = "#ff0000";
    private static const PLANE_COLOR:String = "#00d000";
    private static const TRIANGLE_COLOR:String = "#00d4cd";
    private static const GRAY_COLOR:String = "#737373";
    private static const BORDER_COLOR:String = "#ffffff";
    private static const BORDER_WIDTH:int = 6;

    private static function initMaterials():void {
      if(planeMaterial != null) {
        return;
      }
      planeMaterial = new THREE.MeshPhongMaterial({
            "map": new THREE.CanvasTexture(createPlaneTexture(PLANE_COLOR)),
            "shininess": 5
          });

      boxMaterial = new THREE.MeshPhongMaterial({
            "map": new THREE.CanvasTexture(createPlaneTexture(BOX_COLOR)),
            "shininess": 5
          });

      grayMaterial = new THREE.MeshPhongMaterial({
            "map": new THREE.CanvasTexture(createPlaneTexture(GRAY_COLOR)),
            "shininess": 5
          });

      triangleMaterial = new THREE.MeshPhongMaterial({
            "map": new THREE.CanvasTexture(createTriangleTexture(TRIANGLE_COLOR)),
            "shininess": 5
          });

      grayTriangleMaterial = new THREE.MeshPhongMaterial({
            "map": new THREE.CanvasTexture(createTriangleTexture(GRAY_COLOR)),
            "shininess": 5
          });
    }

    public static function createPlaneTexture(color:String):* {
      var canvas:* = document.createElement("canvas");
      canvas.width = canvas.height = TEXTURE_SIZE;
      var ctx:* = canvas.getContext("2d");
      ctx.fillStyle = color;
      ctx.fillRect(0,0,canvas.width,canvas.height);
      ctx.strokeStyle = BORDER_COLOR;
      ctx.lineWidth = BORDER_WIDTH;
      ctx.strokeRect(0,0,canvas.width,canvas.height);
      return canvas;
    }

    private static function createTriangleTexture(color:String):* {
      var canvas:* = document.createElement("canvas");
      canvas.width = canvas.height = TEXTURE_SIZE;
      var ctx:* = canvas.getContext("2d");
      ctx.fillStyle = BORDER_COLOR;
      ctx.fillRect(0,0,canvas.width,canvas.height);
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.moveTo(0,0);
      ctx.lineTo(canvas.width,canvas.height);
      ctx.lineTo(0,canvas.height);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = BORDER_COLOR;
      ctx.lineWidth = BORDER_WIDTH;
      ctx.strokeRect(0,0,canvas.width,canvas.height);
      return canvas;
    }

    public static function setGrayMaterial(mesh:*):void {
      mesh["material"] = mesh.name == COLLISION_TRIANGLE ? grayTriangleMaterial : grayMaterial;
    }

    public static function setColorMaterial(mesh:*):void {
      switch(mesh.name) {
        case COLLISION_PLANE:
          mesh["material"] = planeMaterial;
          break;
        case COLLISION_BOX:
          mesh["material"] = boxMaterial;
          break;
        case COLLISION_TRIANGLE:
          mesh["material"] = triangleMaterial;
          break;
      }
    }
  }
}
