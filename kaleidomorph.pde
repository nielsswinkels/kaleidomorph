import gab.opencv.*;
import java.awt.*;
import processing.video.*;

OpenCV opencv;
Capture video;
Rectangle[] faces;

// Scaling down the video
int scl = 2;
int TIMEOUT = 500; // delay before taking a picture
int startTime;

void setup() {
  size(640, 480);
  video = new Capture(this, width/scl, height/scl);
  opencv = new OpenCV(this, width/scl, height/scl);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
  
  video.start();
  startTime = millis();
}

int prevAmountFaces = 0;

void draw() {
  // fill the screen with white
  background(255);
  scale(scl);
  //image(opencv.getInput(), 0, 0);
  opencv.loadImage(video);
  
  // show the camera image
  //image(video,0,0);
  // draw a green recangle on all detected faces
  //rectangleAroundFaces();
  
  faces = opencv.detect();

  if(faces.length > prevAmountFaces)
  {
    // more faces than before
    println("more faces than before");
    startTime = millis();
  }
  else if (faces.length < prevAmountFaces)
  {
    // less faces than before
    startTime = millis();
  }
  else
  {
    // no new faces
    //startTime = millis(); 
  }
  
  println(startTime-millis());
  
  if(faces.length > 0 && millis() - startTime > TIMEOUT)
  {
    displayFace();
    //pause();
  }

  
  
  prevAmountFaces = faces.length;
}

void displayFace()
{
  println("displaying face");
  
  // parameters for the location of the morphed face
  int faceX = 100;
  int faceY = 100;
  
  Rectangle f =  faces[faces.length-1];
  PGraphics pic = createGraphics(f.width,f.height);
  pic.beginDraw();
  pic.image(video, -f.x, -f.y);
  pic.endDraw();
  //pic = loadImage(video.read());
  image(pic, faceX,faceY, 100,100);
  PImage imgNose = loadImage("img/nose/lappstiftet.png");
  image(imgNose, faceX+35, faceY+10, 35,55);
  PImage imgHat = loadImage("img/hat/kuggen.png");
  image(imgHat, faceX-10, faceY-30, 120,60);
  
  PImage imgEarLeft = loadImage("img/ear/fiskekyrkan.png");
  image(imgEarLeft, faceX-20, faceY+15, 50,40);
  
  PImage imgEarRight = loadImage("img/ear/fiskekyrkan2.png");
  image(imgEarRight, faceX+70, faceY+15, 50,40);
}

void rectangleAroundFaces()
{
  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);
  for (int i = 0; i < faces.length; i++) {
    rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
  }
}

void captureEvent(Capture c) {
  c.read();
}

void pause()
{
  try {
      Thread.sleep(1000);                 //1000 milliseconds is one second.
  } catch(InterruptedException ex) {
      Thread.currentThread().interrupt();
  } 
}

