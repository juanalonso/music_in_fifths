import gab.opencv.*;
import processing.video.*;
import processing.sound.*;

int NUMFILES = 35;

public enum States {
  waitingForCam, calibrating, waitingForStart, playing, playingAndNext, end
};
States currentState = States.waitingForCam;

int currentLoop = 0;

int calibTime = 0;
int lastFlowEvent = 0;

OpenCV opencv;
PVector flowScale = new PVector(40, 40);
PVector aveFlow = new PVector(0, 0);

float mainX, mainY, mainW, mainH;
Capture video;

SoundFile[] loop = new SoundFile[NUMFILES];
int[] loopStartedAt = new int[NUMFILES];
//Reverb[] reverb = new Reverb[NUMFILES];
//boolean[] isProcessingReverb =  new boolean[NUMFILES];

void setup() {

  size(640, 520);
  noFill();
  strokeWeight(3);
  background(0);
  textSize(22); 

  mainW = 100;
  mainH = 150;
  mainX = width/2-mainW/2;
  mainY = (height-40)/2-mainH/2;

  video = new Capture(this, 640, 480);
  video.start();

  opencv = new OpenCV(this, width/4, (height-40)/4);

  for (int f=0; f<NUMFILES; f++) {
    println("Reading file " + (f+1) + "/" + NUMFILES); 
    loop[f] = new SoundFile(this, "mif "+ (f+1) +".wav");  
    loop[f].stop();
    loopStartedAt[f] = -1000;
    //reverb[f] = new Reverb(this);
    //reverb[f].set(0.9, 0.1, 0.3);
    //isProcessingReverb[f] = false;
  }
}



void draw() {


  //UPDATE
  PImage videoScaled = video.get();
  videoScaled.resize(width/4, (height-40)/4);  
  opencv.loadImage(videoScaled);

  switch (currentState) {
  case calibrating:

    if (millis()-calibTime>2000) {
      currentState = States.waitingForStart;
      log("Waiting for start signal");
    }
    break;


  case waitingForStart:

    if (flowEvent()) {
      lastFlowEvent = millis();
      currentState = States.playing;
    }
    break;


  case playing:

    if (flowEvent()) {

      currentState = States.playingAndNext;
      log("Waiting for fragment "+(currentLoop + 1)+" to finish");
    } else if (loop[currentLoop].position()==0 &&  millis()-loopStartedAt[currentLoop]>1000) {

      loop[currentLoop].play();
      loopStartedAt[currentLoop]=millis();

      /*
      if (!isProcessingReverb[currentLoop]) {
       reverb[currentLoop].process(loop[currentLoop]);
       isProcessingReverb[currentLoop] = true;
       }
       */

      log("Fragment "+ (currentLoop+1));
    } 
    break;


  case playingAndNext:

    if (loop[currentLoop].position()==0) {
      currentLoop = (currentLoop+1)%NUMFILES;
      lastFlowEvent = millis();
      if (currentLoop!=0) {
        currentState = States.playing;
      } else { 
        currentState = States.end;
        log("End of the performance");
      }
    }
  default:
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
  case waitingForStart: 
    stroke(20, 240, 20);
    if (aveFlow.y>0) {
      strokeWeight(5);
      line(mainX + mainW/2, 
        mainY, 
        mainX + mainW/2, 
        mainY + min(aveFlow.y*flowScale.y*4, (height-40)/2));
      strokeWeight(3);
    }
    //ellipse(mainX + mainW/2, mainY + mainH/2, 5, 5);
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


void log(String logMessage) {
  println(logMessage);
  background(0);
  text(logMessage, 12, 507);
}


boolean flowEvent() {

  opencv.calculateOpticalFlow();
  aveFlow = opencv.getAverageFlowInRegion((int)mainX/4, (int)mainY/4, (int)mainW/4, (int)mainH/4);

  return (aveFlow.y*flowScale.y > 50 && millis()-lastFlowEvent>750);
}
