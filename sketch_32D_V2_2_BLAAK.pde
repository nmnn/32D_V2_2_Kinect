import processing.opengl.*;

import SimpleOpenNI.*;

import wblut.math.*;
import wblut.processing.*;
import wblut.core.*;
import wblut.hemesh.*;
import wblut.geom.*;



HE_Mesh mesh;
WB_Render render;

boolean      handsTrackFlag = false;
PVector      handVec = new PVector();
ArrayList    handVecList = new ArrayList();
int          handVecListSize = 30;
String       lastGesture = "";

SimpleOpenNI context;

float easing = 0.05;
float x;
float y;
float z;
float targetX, targetY, targetZ;
float theta1 = 0; //For rotation

//this is added for a modifier
HEM_Extrude modifier;

PImage fader;

//--------------------------------------------SETUP-----------------------------------------// 
void setup() {
  size(1024, 768, OPENGL);
  background(2); // adjust this value to control fade rate  
  fader = get();  
  background(0);
  
  context = new SimpleOpenNI(this);
  context.setMirror(true);
  context.enableGesture();
  context.enableHands();
    
  context.addGesture("Wave");
  context.addGesture("Click");
  context.addGesture("RaiseHand");
     
  fill (255);
   
  createMesh();
       
  // load the subdividor type
  HES_PlanarMidEdge subdividor=new HES_PlanarMidEdge();
  mesh.subdivide(subdividor,2);

  //create a new modifier of extrude type
  modifier=new HEM_Extrude();
   
  //render
  render=new WB_Render(this);
}

//--------------------------------------------DRAW-----------------------------------------// 
void draw() {
  context.update();
 
  // draw the 3d point depth map
  int[]   depthMap = context.depthMap();
  int     steps   = 3;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;
 
  translate(0,0,z-3000);  // set the rotation center of the scene 1000 infront of the camera

  targetZ = handVec.z;
  float dz = targetZ - z;
  if(abs(dz) > 1) {
    z += dz * easing;
  }


  if(handsTrackFlag)  
  {
    pushStyle();
      //stroke(255,0,0,0);
      noFill();
      Iterator itr = handVecList.iterator(); 
      beginShape();
        while( itr.hasNext() ) 
        { 
          PVector p = (PVector) itr.next(); 
          vertex(p.x,p.y,p.z);
        }
      endShape();   

      //stroke(255,0,0);
      //strokeWeight(4);
      point(handVec.x,handVec.y,handVec.z);
    popStyle();   
  }
  
  //background(0);
  directionalLight(255, 255, 255, 1, 1, -1);
  directionalLight(127, 127, 127, -1, -1, 1);
  translate(width/2, height/2, 100);
 
  // rotating the egometry 
  if (handsTrackFlag == true) {
    rotateY(x*1.0f/width*TWO_PI);
  } else {
    rotateY(theta1*1.0f/width*TWO_PI);
  }
  if (handsTrackFlag == true) {
  rotateX(y*1.0f/height*TWO_PI);
  } else {
    rotateX(theta1*1.0f/height*TWO_PI);
  }
  stroke(0);
  render.drawEdges(mesh);
  noStroke();
  render.drawFaces(mesh);
 
  targetX = handVec.x;
  float dx = targetX - x;
  if (abs(dx) > 1) {
   x += dx * easing;
  }
 
  targetY = handVec.y;
  float dy = targetY - y;
  if(abs(dy) > 1) {
    y += dy * easing;
  }
 
  update();
  
  theta1 += 0.72; //Rotate further each draw
 
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();
  // 2D code
  //fill(255, 10); // semi-transparent white
  //rect(0, 0, width, height);
  // fade towards white  
  blend(fader,0,0,width,height,0,0,width,height,DIFFERENCE);
  hint(ENABLE_DEPTH_TEST);
  
  
}

//--------------------------------------------CREATEMESH-----------------------------------------//
 //creating the initial geometry
void createMesh(){
   
  //calling the function create a dodecahedron
  HEC_Dodecahedron creator=new HEC_Dodecahedron();
  //the parameters of the edge - number relates to size
  creator.setEdge(150);
   // at a guess, this creates the mesh between the lines
  mesh=new HE_Mesh(creator);
}

//--------------------------------------------HANDS-----------------------------------------//
// hand events
void onCreateHands(int handId,PVector pos,float time) {
  println("onCreateHands - handId: " + handId + ", pos: " + pos + ", time:" + time);
 
  handsTrackFlag = true;
  handVec = pos;
  
  handVecList.clear();
  handVecList.add(pos);
}

void onUpdateHands(int handId,PVector pos,float time) {
  //println("onUpdateHandsCb - handId: " + handId + ", pos: " + pos + ", time:" + time);
  handVec = pos;
  
  handVecList.add(0,pos);
  if(handVecList.size() >= handVecListSize)
  { // remove the last point 
    handVecList.remove(handVecList.size()-1); 
  }
}

void onDestroyHands(int handId,float time) {
  println("onDestroyHandsCb - handId: " + handId + ", time:" + time);
  handsTrackFlag = false;
  context.addGesture(lastGesture);
}

// gesture events
void onRecognizeGesture(String strGesture, PVector idPosition, PVector endPosition) {
  println("onRecognizeGesture - strGesture: " + strGesture + ", idPosition: " + idPosition + ", endPosition:" + endPosition);
  lastGesture = strGesture;
  context.removeGesture(strGesture); 
  context.startTrackingHands(endPosition);
}

void onProgressGesture(String strGesture, PVector position,float progress) {
  //println("onProgressGesture - strGesture: " + strGesture + ", position: " + position + ", progress:" + progress);
}

//--------------------------------------------UPDATE-----------------------------------------//
void update() {
  createMesh();
 
  // load the subdividor type
  HES_PlanarMidEdge subdividor=new HES_PlanarMidEdge();
  mesh.subdivide(subdividor,2);
   
  //create a new modifier of extrude type
  modifier=new HEM_Extrude();
   
  //extrude modifier parameters
  modifier.setDistance(y+x/2);// extrusion distance, set to 0 for inset faces - (I could contrle this and add a mathematical equation to it MS)
  modifier.setRelative(false);// treat chamfer as relative to face size or as absolute value
  modifier.setChamfer(4);// chamfer for non-hard edges
  modifier.setHardEdgeChamfer(100+y);// chamfer for hard edges handVec.x,handVec.y,handVec.z
  modifier.setThresholdAngle(1.5*HALF_PI);// treat edges sharper than this angle as hard edges
  modifier.setFuse(true);// try to fuse planar adjacent planar faces created by the extrude
  modifier.setFuseAngle(0.05*z);// threshold angle to be considered coplanar
  modifier.setPeak(true);//if absolute chamfer is too large for face, create a peak on the face
  mesh.modify(modifier);
}

//--------------------------------------------EOF-----------------------------------------//
