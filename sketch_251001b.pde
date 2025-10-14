
//Import video library
import processing.video.*;

float x;
float y;
Capture video;

//Initialise Capture object inside Constructor
void setup() {
  //Match sketch size to device's resolution
    size(1280, 720);
    x = width/videoScale;
    y = height/videoScale;
    background(0);
     video = new Capture(this, x, y);
     video.start();
}

//Event for when camera image is available to be read
void captureEvent(Capture video) {
   video.read();
}

//Return video output if available
void draw() {
   float another x = 
   float another y = 
       fill (
       stroke(0);
       strokeWeight(10);
       ellipse(x, y, anotherx, anothery);
      }  
