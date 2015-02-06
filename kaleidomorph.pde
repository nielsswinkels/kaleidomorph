import gab.opencv.*;
import java.awt.*;
import processing.video.*;

OpenCV opencv;
Capture video;
Rectangle[] faces;

int START_DELAY = 0; // delay before creating a new morph
int APPROVE_DELAY = 10000; // delay before the picture is saved
int startTime;
int mode = 0; // 0 = idle, 1 = face found, 2 = saving picture

// just some supported resolutions for the logitech webcam c930e:
// 640x360
// 800x600
// 960x540
// 1024x576
// 1280x720
// 1600x896
// 1920x1080
// 2304x1536 (max res)
int VIDEO_RES_WIDTH = 640; // max = 2304x1536 (logitech 1080p)
int VIDEO_RES_HEIGHT = 360;

String[] noseFiles;
String[] earFiles;
String[] hatFiles;

PImage imgNose;
PImage imgEar;
PImage imgHat;
PImage faceMask;

void setup() {
  size(640, 480);
  frame.setResizable(true);
  //size(1024, 768);
  video = new Capture(this, VIDEO_RES_WIDTH, VIDEO_RES_HEIGHT);
  opencv = new OpenCV(this, VIDEO_RES_WIDTH, VIDEO_RES_HEIGHT);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
  
  video.start();
  startTime = millis();
  mode = 0;
  
  textFont(createFont("Georgia", 36));
  
  noseFiles = listFileNames(sketchPath+"/img/nose");
  earFiles = listFileNames(sketchPath+"/img/ear");
  hatFiles = listFileNames(sketchPath+"/img/hat");
  
  faceMask = loadImage(sketchPath+"/img/facemask.png");
}

int prevAmountFaces = 0;

void draw() {
  
  
  // fill the screen with white
  background(255);
  
  opencv.loadImage(video);
  if (mode == 0)
  {
    fill(0);
    textSize(52);
    text("Titta hit!", width/2.0, height/2.0);
    pause();
  }
  
  
  // show the camera image
  //image(video,0,0);
  
  
  faces = opencv.detect();
  
  // draw a green recangle on all detected faces
  rectangleAroundFaces();

  if(faces.length > 0)
  {
    // at least one face detected
    if (mode == 0)
    {
      startTime = millis();
      mode = 1;
      println("mode="+mode);
    }
  }
  else
  {
    // no faces detected
    //startTime = millis();
   mode = 0;
   println("mode="+mode);
  }
  
  if(mode == 1 && millis() - startTime > START_DELAY)
  {
    mode = 2;
    println("mode="+mode);
    
    startTime = millis();
    
    imgNose = loadRandom("nose", noseFiles);
    imgHat = loadRandom("hat", hatFiles);
    imgEar = loadRandom("ear", earFiles);
  }
  
  if(mode == 2)
  {
    displayFace();
  }

  
  
  prevAmountFaces = faces.length;
  //println("framerate:"+frameRate);
}

void displayFace()
{
  // parameters for the location of the morphed face
  int faceSize = 200;
  int faceX = int(width/2.0-faceSize/2.0);
  int faceY = int(height/2.0-faceSize/2.0);
  
  Rectangle f =  faces[faces.length-1];
  PGraphics pic = createGraphics(f.width,f.height);
  pic.beginDraw();
  pic.image(video, -f.x, -f.y);
  pic.endDraw();
  //pic = loadImage(video.read());
  
  image(pic, faceX,faceY, faceSize,faceSize);
  image(faceMask, faceX,faceY, faceSize,faceSize);
  
  int buildingsX = int(faceX - (faceSize/2.094240837696335));
  int buildingsY = int(faceY - (faceSize/2.083333333333333));
  int buildingsWidth = int(faceSize * 1.955);
  int buildingsHeight = int(faceSize * 1.6525);
  
  
  image(imgNose, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
  image(imgHat, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
  image(imgEar, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
  
  if (millis() - startTime > APPROVE_DELAY)
  {
    println("Saving picture");
    // save the picture as a file
    saveFrame("output/urbanum####.png");
    mode = 0;
  }
  else
  {
    int seconds = round((APPROVE_DELAY - (millis() - startTime))/1000);
    //println("Saving picture in " + seconds + " seconds");
    textSize(18);
    text("Sparar bilden i " + seconds + " sekunder.", 10, 30);
  }
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


String[] listFileNames(String dir) {
  println("reading filenames in dir " + dir);
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    println("found "+names.length+" files");
    return names;
  } else {
    // If it's not a directory
    println("Warning: this is not a directory:"+dir);
    return null;
  }
}

PImage loadRandom(String dir, String[] files)
{
  return loadImage("img/"+dir+"/"+files[int(random(files.length))]);
}
