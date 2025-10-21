
//Art gallery installation - walk up to the screen interface and discover how it reacts to you!
//The live video feed underneath the grid of ellipses is reactive to:
  //1)live audio volume to control the brightness of the image (the louder you are, the more image you will see!)
  //2)mouse movement to control the ellipses get smaller and full transparency - move mouse to make the image clearer!)
  //3)mouse press to cycle through different shapes


//Import libraries
import processing.video.*;
import ddf.minim.*;

//Declare audio variables
Minim minim;
AudioInput in;

//Declare video variables
int videoScale = 30; //Size of each cell in the grid, ratio of window size to video size
int cols, rows;
Capture video;

//Distance variable
float max_distance;

//Declare shape index array
int shapeIndex = 0;
String[] shapes = {"ellipse", "rect", "triangle"};
int totalShapes = shapes.length;


//Initialise Capture objects inside Constructor
void setup() {
    size(1280, 720, P3D); //Match sketch size to device's resolution
    background(0);
    noStroke();
    
    //Max distance of the mouse effect is the entire canvas
    max_distance = dist(0, 0, width/2, height/2); //Calculating the distance of the canvas 
    
    //Initialise video capture
    cols = width/videoScale;
    rows = height/videoScale;
    video = new Capture(this, 640, 480);
    video.start();
    
    //Initialise audio input
     minim = new Minim(this);
     in = minim.getLineIn(); 
}

//Event for when camera image is available to be read
void captureEvent(Capture video) {
   video.read();
}

//mouse press function cycles through the shape index
void mousePressed() {
  shapeIndex = (shapeIndex+1) % totalShapes;
}

//Draw loop for video, audio and colour
void draw() {
  background(0);
  //Fading trails using transparent black rectangle
  blendMode(BLEND);
  noStroke();
  fill(0, 30);
  rect(0, 0, width*2, height*2);
  
  //Faint camera feed first
  tint(255, 40);
  image(video, 0, 0, width, height);
  noTint();
  
  video.loadPixels();
  
  //Calculate the current volume level
  float volume = 0;
  for(int i = 0; i < in.bufferSize(); i++)
  {
    volume +=abs(in.left.get(i)); //Add absolute amplitude of left channel
  }
  volume /= in.bufferSize(); //Average volume value
  
  //Map volume to brightness pulse range
  float amplified = volume*10; // Increase volume sensitivity
  float brightnessFactor = map(amplified, 0, 0.5, 0.1, 4.0);
  brightnessFactor = constrain(brightnessFactor, 0.1, 4.0);

  //Draw the grid of ellipses
  for (int i = 0; i< cols; i++) {    //Loop for columns
   for (int j = 0; j < rows; j++) {  //Loop for rows
    //Scale up to draw shape at (x, y)
     int x = i*videoScale;
     int y = j*videoScale;
     
     // Map grid coordinates to video pixel coordinates
     int vidX = int(map(i, 0, cols, 0, video.width));
     int vidY = int(map(j, 0, rows, 0, video.height));
     int loc = vidX + vidY * video.width;
     
     //Extract RGB channels and apply pulse based on audio volume
     color c = video.pixels[loc];
     float r = red(c)*brightnessFactor;
     float g = green(c)*brightnessFactor;
     float b = blue(c)*brightnessFactor;
     
     //Base ellipse size on distance to mouse
      float d = dist(mouseX, mouseY, x, y);
      float size = map(d, 0, max_distance, 2, videoScale * 2);
      size = constrain(size, 2, videoScale);
     
     //Base ellipse transparency on distance to mouse
     float alpha = map(d, 0, max_distance, 255, 0);
     alpha = constrain(alpha, 0, 255);
     
     //Call function inside draw
     fill(r, g, b, alpha);
     drawShape(shapeIndex, x, y, size);
   }
  }
}
   
 //Draw ellipse, rect and triangle shapes in a seperate function
   void drawShape(int s, float x, float y, float size) {
     switch(s){
       case 0: //ellipse
       ellipse(x, y, size, size);
       break;
     
       case 1: //rect
       rectMode(CENTER);
       rect(x, y, size/2, size/2);
       break;
       
       case 2: //triangle
       float h = size * 0.866;
       triangle(x, y - h/2, x - size/2, y+h/2, x+size/2, y+h/2);
       break;
     }
   }
     
