import gab.opencv.*;
import processing.video.*;
import processing.sound.*;

int NUMFILES = 14;

public enum States {
  waitingForCam, calibrating, playing, playingAndNext
};
States currentState = States.waitingForCam;

int currentLoop = 0;

int calibTime = 0;

OpenCV opencv;
PVector flowScale = new PVector(55, 55);
PVector aveFlow;

float mainX, mainY, mainW, mainH;
Capture video;

SoundFile[] loop = new SoundFile[NUMFILES];
int[] loopStartedAt = new int[NUMFILES];

void setup() {

  size(640, 500);
  noFill();
  strokeWeight(3);
  background(0);

  mainW = 100;
  mainH = 150;
  mainX = width/2-mainW/2;
  mainY = (height-20)/2-mainH/2;

  video = new Capture(this, 640, 480);
  video.start();

  opencv = new OpenCV(this, width/4, (height-20)/4);

  for (int f=0; f<NUMFILES; f++) {
    println("Reading file " + (f+1) + "/" + NUMFILES); 
    loop[f] = new SoundFile(this, "mif "+ (f+1) +".wav");
    loopStartedAt[f] = -1000;
  }
}



void draw() {


  //UPDATE
  PImage videoScaled = video.get();
  videoScaled.resize(width/4, (height-20)/4);  
  opencv.loadImage(videoScaled);

  if (currentState == States.calibrating) {
    if (millis()-calibTime>2000) {
      currentState = States.playing;
      opencv.calculateOpticalFlow();
      stroke(20, 200, 20);
    }
  } 

  if (currentState == States.playing) {

    opencv.calculateOpticalFlow();
    aveFlow = opencv.getAverageFlowInRegion((int)mainX/4, (int)mainY/4, (int)mainW/4, (int)mainH/4);

    if (aveFlow.y*flowScale.y > 50) {
      currentState = States.playingAndNext;
      
      println("Waiting for next fragment");
      background(0);
      text("Waiting for next fragment", 5, 494);
    }

    if (loop[currentLoop].position()==0 &&  millis()-loopStartedAt[currentLoop]>1000) {
      loop[currentLoop].play();
      loopStartedAt[currentLoop]=millis();
      
      println("Fragment "+ (currentLoop+1) +" ("  + loop[currentLoop].duration() + "s)");
      background(0);
      text("Fragment "+ (currentLoop+1) +" ("  + loop[currentLoop].duration() + "s)", 5, 494);
    }
  }

  if (currentState == States.playingAndNext) {
    if (loop[currentLoop].position()==0) {
      currentLoop = (currentLoop+1)%NUMFILES;
      currentState = States.playing;
      opencv.calculateOpticalFlow();
    }
  }


  //DRAW
  image(video, 0, 0);

  switch(currentState) {
  case calibrating:
    stroke(200);
    break;
  case playingAndNext:
    stroke(100, 150, 255);
    break;
  case playing: 
    stroke(20, 240, 20);
    line(mainX + mainW/2, 
      mainY + mainH/2, 
      mainX + mainW/2, 
      mainY + mainH/2 + aveFlow.y*flowScale.y);
    ellipse(mainX + mainW/2, mainY + mainH/2, 5, 5);
    break;
  default:
  }

  rect(mainX, mainY, mainW, mainH);

  //println(frameRate);
}



void captureEvent(Capture c) {
  c.read();
  if (currentState == States.waitingForCam) {
    calibTime = millis();
    currentState = States.calibrating;
  }
}
