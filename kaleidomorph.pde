import gab.opencv.*;
import java.awt.*;
import processing.video.*;
import java.util.Comparator;
import java.util.Arrays;
import java.io.File;

boolean debug = true;

OpenCV opencv;
Capture video;
PImage videoResized;
Rectangle[] faces;

int START_DELAY = 0*1000; // delay before creating a new morph
int APPROVE_DELAY = 10 *1000; // delay before the picture is saved
int SHOW_MORPH_DELAY = 3 *1000; // how long to display the final saved morph
int startTime;
int mode = 0; // 0 = idle, 1 = face found, 2 = saving picture, 3 = display the saved picture for a while

// parameters for the location of the morphed face
int screenWidth = 1920;
int screenHeight = 1080;
int marginH = 54;
int marginV = 54;
int faceSize = 627;
int faceXRelative = 106; // how much to move the face relative to the buildingsX
int faceYRelative = 172;
int faceX = int(screenWidth / 2.0) + marginH + faceXRelative;
int faceY = marginV + faceYRelative;
int buildingsX = int(screenWidth / 2.0) + marginH;
int buildingsY = marginV;
int buildingsWidth = int(screenWidth/2.0-(marginH*2.0));
int buildingsHeight = int(screenHeight-(marginV*2.0));
int galleryX = marginH;
int galleryY = marginV;
int galleryWidth = buildingsWidth;
int galleryHeight = buildingsHeight;

String[] hejStrings = {"Du är staden.", "Staden är du.", "Kom hit och bli en del av Göteborg!"};
String currentHejString = hejStrings[0];
int hejStringX = 0;
int hejStringY = 0;

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
String[] idleFiles;

PImage imgNose;
PImage imgEar;
PImage imgHat;
PImage imgMouth;
PImage faceMask;
PImage imgIdle;

PImage imgDesk;

int lastMorphNr = 0;
String morphDir;
String[] morphFiles;
int prevNrFiles = 0;
Comparator<File> byModificationDate = new ModificationDateCompare();
int galleryCounter = 0;
PImage galleryImg;

void setup() {
  size(screenWidth, screenHeight);
  frame.setResizable(true);
  video = new Capture(this, VIDEO_RES_WIDTH, VIDEO_RES_HEIGHT);
  opencv = new OpenCV(this, int(VIDEO_RES_WIDTH*openCVScale), int(VIDEO_RES_HEIGHT*openCVScale));
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  
 
  startTime = millis();
  mode = 0;
  
  textFont(createFont("Whitney", 36));
  
  noseFiles = listFileNames(sketchPath+"/img/nose");
  earFiles = listFileNames(sketchPath+"/img/ear");
  hatFiles = listFileNames(sketchPath+"/img/hat");
  mouthFiles = listFileNames(sketchPath+"/img/mouth");
  idleFiles = listFileNames(sketchPath+"/img/idle");
  
  imgIdle = loadRandom("idle", idleFiles);
  
  faceMask = loadImage(sketchPath+"/img/facemask_black.jpg");
  imgDesk = loadImage(sketchPath+"/img/desk.jpg");
  
  morphDir = sketchPath+"/output";
  lastMorphNr = listFileNames(morphDir).length-1;
  if(debug) println("lastMorphNr="+lastMorphNr);
  
  video.start();
}

int prevAmountFaces = 0;


void draw() {
  // fill the screen with white
  background(255);
  
  if(debug) // draw margins for debug
  {
    fill(200);
    noStroke();
    rect(0, 0, screenWidth, marginV);
    rect(0, screenHeight-marginV, screenWidth, marginV);
    
    rect(0, 0, marginH, screenHeight);
    rect(screenWidth-marginH, 0, marginH, screenHeight);
    
    rect(screenWidth/2.0-marginH, 0, marginH*2.0, screenHeight);
  }
  
  //*********
  // gallery
  
  displayGallery();
  
  //***************
  
  
  PImage videoResized = new PImage(video.width, video.height);
  video.loadPixels();
  videoResized.loadPixels();
  videoResized.pixels = video.pixels;
  videoResized.updatePixels();
  videoResized.resize(opencv.width, opencv.height);
  opencv.loadImage(videoResized);
  
  
  if (mode == 0)
  {
    // display an image in idle mode
    println("new width:"+resizeWidth(imgIdle.width, imgIdle.height, buildingsHeight));
    image(imgIdle, buildingsX, buildingsY, resizeWidth(imgIdle.width, imgIdle.height, buildingsHeight), buildingsHeight);
    fill(255);
    textSize(52);
    
    if(frameCount%20==0)
    {
      currentHejString = hejStrings[int(random(hejStrings.length))];
      hejStringX = int(random(width/6.0, width/3.0));
      hejStringY = int(height/4.0);
    }
    
    //text(currentHejString, hejStringX, hejStringY);
    hejStringX += 5;
    
    //pause();
  }
  
  
  // show the camera image
  //image(video,0,0, video.width, video.height);
  faces = opencv.detect();
  
  // draw a green recangle on all detected faces
  //rectangleAroundFaces();
  
  if(debug) println(faces.length + " faces found");
  //if (true) return;

  if(faces.length == 0)
  {
    // no faces detected
    
    if(mode != 0) // we just switched back to mode 0
    {
      println("new idle image");
      imgIdle = loadRandom("idle", idleFiles); // new idle image
    }
    
    mode = 0;
    if(debug) println("mode="+mode);
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
        PImage imgDeskFade = imgDesk;
        int[] mask = new int[imgDesk.width * imgDesk.height];
        int maskValue = max(255-int((millis() - startTime)/(1.0*START_DELAY)*255),0); // fadeout the desk image
        for (int i = 0; i < mask.length; i++) {
          mask[i] = maskValue;
        }
        println("mask"+mask[0]);
        imgDeskFade.mask(mask);
        //image(imgDeskFade, 0, 0, (height/(1.0*imgDesk.height))*imgDesk.width,height);
        
        if(millis() - startTime > START_DELAY)
        {
          mode = 2;
          if(debug) println("mode="+mode);
          
          startTime = millis();
          
          imgNose = loadRandom("nose", noseFiles);
          imgHat = loadRandom("hat", hatFiles);
          imgEar = loadRandom("ear", earFiles);
          imgMouth = loadRandom("mouth", mouthFiles);
        }
        break;
      case 2:  // display the generated morph
      
        PGraphics saveMorph = createGraphics(buildingsWidth, buildingsHeight); // create an image to save the morph as a file with transparency
        saveMorph.beginDraw();
        
        Rectangle f =  faces[0];
        PGraphics pic = createGraphics(int(f.width/openCVScale),int(f.height/openCVScale));
        pic.beginDraw();
        pic.image(video, -f.x/openCVScale, -f.y/openCVScale);
        pic.endDraw();
        
        PImage faceImage = pic.get(); // get the face as an image from the video stream
        faceImage.resize(faceSize,faceSize); // make it always the same square size
        faceMask.resize(faceImage.width, faceImage.height);
        faceImage.mask(faceMask); // apply mask to cut out the face shape
        image(faceImage, faceX,faceY, faceSize,faceSize);
        saveMorph.image(faceImage, faceXRelative, faceYRelative, faceSize,faceSize);
        
        
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
        
        
        image(imgNose, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
        image(imgHat, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
        image(imgEar, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
        image(imgMouth, buildingsX, buildingsY, buildingsWidth, buildingsHeight);
        
        saveMorph.image(imgNose, 0, 0, buildingsWidth, buildingsHeight);
        saveMorph.image(imgHat, 0, 0, buildingsWidth, buildingsHeight);
        saveMorph.image(imgEar, 0, 0, buildingsWidth, buildingsHeight);
        saveMorph.image(imgMouth, 0, 0, buildingsWidth, buildingsHeight);
        
        saveMorph.endDraw();
        
        
        if (millis() - startTime > APPROVE_DELAY)
        {
          if(debug) println("Saving picture");
          // save the picture as a file
          lastMorphNr++;
          //saveFrame("output/urbanum"+lastMorphNr+".png");
          saveMorph.save("output/urbanum"+lastMorphNr+".png");
          mode = 3;
          startTime = millis();
        }
        else
        {
          int seconds = round((APPROVE_DELAY - (millis() - startTime))/1000);
          fill(0);
          textSize(18);
          text("Sparar bilden om " + seconds + " sekunder.", 10, 30);
        }
        break;
      case 3: // display the saved image for a while and go back to idle mode
        background(0);
        if(millis() - startTime < SHOW_MORPH_DELAY)
        {
          PImage morph = loadImage("output/urbanum"+lastMorphNr+".png");
          int morphX = int(width/2.0-morph.width/2.0);
          int morphY = int(height/4.0-morph.height/2.0)+100;
          image(morph, morphX, morphY, morph.width, morph.height);
        }
        else
        {
          mode = 0;
        }
        break;
    }
  }

  prevAmountFaces = faces.length;
  //if(debug) println("framerate:"+frameRate);
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
  if(debug) println("reading filenames in dir " + dir);
  File file = new File(dir);
  if (file.isDirectory()) {
    File[] files = file.listFiles();
    Arrays.sort(files, byModificationDate);
    String[] names = new String[files.length];
    for(int i = 0; i < files.length;i++)
    {
      names[i] = files[i].getName();
    }
    if(debug) println("found "+names.length+" files");
    return names;
  } else {
    // If it's not a directory
    println("Warning: this is not a directory:"+dir);
    return null;
  }
}

class ModificationDateCompare implements Comparator<File> {
  public int compare(File f1, File f2) {
    return Long.valueOf(f1.lastModified()).compareTo(f2.lastModified());    
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

void displayGallery()
{
  morphFiles = listFileNames(morphDir);
  if(morphFiles == null ||morphFiles.length <= 0)
  {
    fill(0);
    println("Error: no images found in dir "+morphDir+" to display in the gallery.");
    return;
  }
  
  if(galleryImg == null || galleryCounter%100 == 0 || prevNrFiles < morphFiles.length)
  {
    galleryCounter = 0;
    galleryImg = loadImage(morphDir + "/" + morphFiles[int(random(morphFiles.length))]);
    if(prevNrFiles < morphFiles.length)
    {
      galleryImg = loadImage(morphDir + "/" + morphFiles[morphFiles.length-1]);
    }
  }
  image(galleryImg, galleryX, galleryY, galleryWidth, galleryHeight);
  prevNrFiles = morphFiles.length;
  galleryCounter++;
}

int resizeWidth(int originalWidth, int originalHeight, int newHeight)
{
  return int((newHeight/(1.0*originalHeight))*originalWidth);
}

int resizeHeight(int originalWidth, int originalHeight, int newWidth)
{
  return int((newWidth/(1.0*originalWidth))*originalHeight);
}
