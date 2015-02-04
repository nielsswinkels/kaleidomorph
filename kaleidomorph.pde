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
  scale(scl);
  //image(opencv.getInput(), 0, 0);
  opencv.loadImage(video);
  image(video,0,0);
  
  
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
    Rectangle f =  faces[faces.length-1];
    PGraphics pic = createGraphics(f.width,f.height);
    pic.beginDraw();
    pic.image(video, -f.x, -f.y);
    pic.endDraw();
    //pic = loadImage(video.read());
    image(pic, 20,20, 100,100);
    PImage imgNose = loadImage("img/nose/lappstiftet.png");
    image(imgNose, 55, 30, 35,55);
    PImage imgHat = loadImage("img/hat/kuggen.png");
    image(imgHat, 10, -10, 120,60);
    
    PImage imgEarLeft = loadImage("img/ear/fiskekyrkan.png");
    image(imgEarLeft, -10, 35, 50,40);
    
    PImage imgEarRight = loadImage("img/ear/fiskekyrkan2.png");
    image(imgEarRight, 90, 35, 50,40);
    
    
    println("displaying face");
    //pause();
  }

  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);
  for (int i = 0; i < faces.length; i++) {
    rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
  }
  
  prevAmountFaces = faces.length;
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

