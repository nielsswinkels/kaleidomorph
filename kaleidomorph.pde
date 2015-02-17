import gab.opencv.*;
import java.awt.*;
import processing.video.*;

boolean debug = true;

OpenCV opencv;
Capture video;
PImage videoResized;
Rectangle[] faces;

int START_DELAY = 0; // delay before creating a new morph
int APPROVE_DELAY = 30000; // delay before the picture is saved
int SHOW_MORPH_DELAY = 2000; // how long to display the final saved morph
int startTime;
int mode = 0; // 0 = idle, 1 = face found, 2 = saving picture, 3 = display the saved picture for a while

// parameters for the location of the morphed face
int faceSize = 600;
int faceX = 0;
int faceY = 0;

String[] hejStrings = {"Du är staden.", "Staden är du.", "Kom hit och bli en del av Göteborg!"};
String currentHejString = hejStrings[0];

// just some supported resolutions for the logitech webcam c930e:
// 640x360
// 800x600
// 960x540
// 1024x576
// 1280x720
// 1600x896
// 1920x1080
// 2304x1536 (max res)
int VIDEO_RES_WIDTH = 2304; // max = 2304x1536 (logitech 1080p)
int VIDEO_RES_HEIGHT = 1536;

float openCVScale = 0.1;

String[] noseFiles;
String[] earFiles;
String[] hatFiles;
String[] mouthFiles;

PImage imgNose;
PImage imgEar;
PImage imgHat;
PImage imgMouth;
PImage faceMask;

int lastMorphNr = 0;

void setup() {
  size(640, 480);
  frame.setResizable(true);
  //size(1024, 768);
  video = new Capture(this, VIDEO_RES_WIDTH, VIDEO_RES_HEIGHT);
  opencv = new OpenCV(this, int(VIDEO_RES_WIDTH*openCVScale), int(VIDEO_RES_HEIGHT*openCVScale));
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  
 
  startTime = millis();
  mode = 0;
  
  textFont(createFont("Georgia", 36));
  
  noseFiles = listFileNames(sketchPath+"/img/nose");
  earFiles = listFileNames(sketchPath+"/img/ear");
  hatFiles = listFileNames(sketchPath+"/img/hat");
  mouthFiles = listFileNames(sketchPath+"/img/mouth");
  
  faceMask = loadImage(sketchPath+"/img/facemask_black.jpg");
  
  lastMorphNr = listFileNames(sketchPath+"/output").length-1;
  println("lastMorphNr="+lastMorphNr);
  
  video.start();
}

int prevAmountFaces = 0;


void draw() {
  int faceX = int(width/2.0-faceSize/2.0);
  int faceY = int(height/4.0-faceSize/2.0)+100;
  
  // fill the screen with white
  background(255);
  
  
  PImage videoResized = new PImage(video.width, video.height);
  video.loadPixels();
  videoResized.loadPixels();
  videoResized.pixels = video.pixels;
  videoResized.updatePixels();
  videoResized.resize(opencv.width, opencv.height);
  opencv.loadImage(videoResized);
  
  
  if (mode == 0)
  {
    fill(0);
    textSize(52);
    
    if(frameCount%20==0)
      currentHejString = hejStrings[int(random(hejStrings.length))];
    text(currentHejString, random(width/4.0, width/2.0), random(height/5.0, height/2.0));
    //pause();
  }
  
  
  // show the camera image
  //image(videoResized,0,0, video.width, video.height);
  faces = opencv.detect();
  
  // draw a green recangle on all detected faces
  rectangleAroundFaces();
  
  println(faces.length);
  //if (true) return;

  if(faces.length == 0)
  {
    // no faces detected
    mode = 0;
    println("mode="+mode);
  }
  else  // at least one face detected, let's do something
  {
    switch(mode)
    {
      case 0:  // found at least one face
        startTime = millis();
        mode = 1;
        if(debug) println("mode="+mode);
        break;
      case 1:  // wait untill start delay has passed 
        if(millis() - startTime > START_DELAY)
        {
          mode = 2;
          println("mode="+mode);
          
          startTime = millis();
          
          imgNose = loadRandom("nose", noseFiles);
          imgHat = loadRandom("hat", hatFiles);
          imgEar = loadRandom("ear", earFiles);
          imgMouth = loadRandom("mouth", mouthFiles);
        }
        break;
      case 2:  // display the generated morph
        Rectangle f =  faces[0];
        PGraphics pic = createGraphics(int(f.width/openCVScale),int(f.height/openCVScale));
        pic.beginDraw();
        pic.image(video, -f.x/openCVScale, -f.y/openCVScale);
        pic.endDraw();
        
        PImage faceImage = pic.get();
        faceImage.resize(faceSize,faceSize);
        faceMask.resize(faceImage.width, faceImage.height);
        faceImage.mask(faceMask);
        image(faceImage, faceX,faceY, faceSize,faceSize);
        
        // if at least 3 faces are found
        if(faces.length > 2)
        {
          Rectangle f2 = faces[1];
          Rectangle f3 = faces[2];
          PImage face2 = cutOutRectangle(video, f2, openCVScale);
          PImage face3 = cutOutRectangle(video, f3, openCVScale);
          
          PImage eye2 = cutOutEye(face2);
          PImage eye3 = cutOutEye(face3);
          
          if(eye2 != null)
            image(eye2, faceX-100+faceSize/2.0, faceY+faceSize/3.0, eye2.width, eye2.height);
          if(eye3 != null)
            image(eye3, faceX+100+faceSize/2.0, faceY+faceSize/3.0, eye3.width, eye3.height);
        }
        else if (faces.length > 1) // if 2 faces are found
        {
          
        }
        
        int buildingsX = int(faceX - (faceSize/2.094240837696335));
        int buildingsY = int(faceY - (faceSize/2.083333333333333));
        int buildingsWidth = int(faceSize * 1.955);
        int buildingsHeight = int(faceSize * 1.6525);
        
        /*
        image(imgNose, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
        image(imgHat, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
        image(imgEar, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
        image(imgMouth, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
        */
        if (millis() - startTime > APPROVE_DELAY)
        {
          println("Saving picture");
          // save the picture as a file
          lastMorphNr++;
          saveFrame("output/urbanum"+lastMorphNr+".png");
          mode = 3;
          startTime = millis();
        }
        else
        {
          int seconds = round((APPROVE_DELAY - (millis() - startTime))/1000);
          //println("Saving picture in " + seconds + " seconds");
          textSize(18);
          text("Sparar bilden om " + seconds + " sekunder.", 10, 30);
        }
        break;
      case 3: // display the saved image for a while and go back to idle mode
        if(millis() - startTime < SHOW_MORPH_DELAY)
        {
          image(loadImage("output/urbanum"+lastMorphNr+".png"), 0, 0, width, height);
        }
        else
        {
          mode = 0;
        }
        break;
    }
  }

  prevAmountFaces = faces.length;
  //println("framerate:"+frameRate);
}

PImage cutOutRectangle(PImage source, Rectangle rect, float scale)
{
  PGraphics pic = createGraphics(int(rect.width/scale),int(rect.height/scale));
  pic.beginDraw();
  pic.image(source, -rect.x/scale, -rect.y/scale);
  pic.endDraw();
  return pic.get();
}

void rectangleAroundFaces()
{
  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);
  for (int i = 0; i < faces.length; i++) {
    rect(faces[i].x/openCVScale, faces[i].y/openCVScale, faces[i].width/openCVScale, faces[i].height/openCVScale);
  }
}

void rectangleAround(Rectangle[] objects, int threshold)
{
  noFill();
  stroke(255, 0, 0);
  strokeWeight(3);
  for (int i = 0; i < objects.length; i++) {
    stroke(255, 0, 0);
    if(objects[i].y > threshold)
      stroke(0, 0, 255);
    rect(objects[i].x, objects[i].y, objects[i].width, objects[i].height);
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

PImage cutOutEye(PImage face)
{
  OpenCV opencv2 = new OpenCV(this, face.width, face.height); // FIXME does this new create heap problems?
  opencv2.loadCascade(OpenCV.CASCADE_EYE);
  
  opencv2.loadImage(face);
  Rectangle[] eyes2 = opencv2.detect();
  
  Rectangle eye2 = null;
  for (int i = 0; i < eyes2.length; i++)
  {
    if(eyes2[i].y < face.height/2.0)
    {
      eye2 = eyes2[i];
      break;
    }
  }
  image(face,0,0);
  rectangleAround(eyes2, int(face.height/2.0));
  if(eye2 != null)
  {
    return cutOutRectangle(face, eye2, 1.0);
  }
  return null;
}
