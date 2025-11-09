/*
'De-image'
An interactive audiovisual installation that transforms your movements and sounds into a live, reactive artwork.
1. Audio input affects organic shape system's speed, brightness, colour and audio output frequency, by easing between 'calm' and 'chaotic' states.
2. Mouse movement creates warps the shapes, and mouse click changes the shape type between ellipses, squares and stars.
3. Live video feed is abstractly displayed in the 'calm' state shapes. Fallback text displays if video feed is unavailable.
*/

// - GLOBAL VARIABLES - 
//Import video and audio libraries
import processing.video.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

//Declare video and audio objects
Capture video;
Minim minim;
AudioInput in;
AudioOutput out;
Oscil osc; //Sound generator

//Declare variables for the noise-based shape system
int numShapes = 250; //Number of shapes drawn
float[] xPos, yPos; //Current shape positions
float[] xNoise, yNoise; //Perlin noise offsets for smooth random motion
float[] sizeOffsets; //Randomised size variation for each shape
// Declare variables for shape colours
color[] calmColors;    //'Calm' state: Filled with live video feed pixels
color[] chaoticColors; //'Chaotic' state: Filled with random saturated colors
//Declare shape index array
int shapeIndex = 0;
String[] shapes = {"ellipse", "rect", "star"};

//Declare variables for video and audio
int shapeScale = 25; //Base scaling for shape size
//Declare variables for shape motion speed
float calmSpeed = 0.0001; //'Calm' state: Drifting motion
float chaoticSpeed = 0.1; //'Chaotic' state: Erratic motion
//Declare variables for brightness
float minBrightness = 0.1;
float maxBrightness = 4.0;
//Declare variables for warp effect parameters
float maxDistance;
float warpAmount = 0.1; //How strongly shpaes are pulled toward the mouse
//Declare variables for audio frequency parameters
float calmFreq = 220; //'Calm' state: Low oscillator frequency
float chaoticFreq = 880; //'Chaotic' state: High oscillator frequency

//Declare text instructions array
String[] instructionsArray = {
  "Welcome... make a noise",
  "Move your mouse",
  "Sing or clap a song",
  "Click your mouse",
  "Turn your volume all the way down",
  "Now turn your volume up",
};
//Declare text instruction cycle parameters
int instructionIndex = 0;
String currentInstruction = instructionsArray[0];
float textAlpha = 0; //Alpha transparency for fade-in
float fadeSpeed = 2; //Alpha increments by 2 each frame
int cycleInterval = 10 * 1000; //Switch message every 10 seconds
int lastCycle = 0;


// - SETUP -
void setup() {
  fullScreen();
  noStroke();
  //Initialise video capture
  video = new Capture(this, width, height);
  video.start();
  //Initialise audio input and output
  minim = new Minim(this); 
  in = minim.getLineIn(); //Monitor AudioInput from mic
  out = minim.getLineOut(); //Monitor AudioOutput
  //Oscillator with frequency, amplitude and sine wavesform shape
  osc = new Oscil(calmFreq, 0.1f, Waves.SINE);
  osc.patch(out); //Connect oscillator to the output speakers

  //Initialise arrays
  xPos = new float[numShapes];
  yPos = new float[numShapes];
  xNoise = new float[numShapes];
  yNoise = new float[numShapes];
  sizeOffsets = new float[numShapes];
  calmColors = new color[numShapes];
  chaoticColors = new color[numShapes];

  //Initialise perlin noise offsets and random shape attributes
  for (int i = 0; i < numShapes; i++) { 
    xNoise[i] = random(5000); //Random noise seeds
    yNoise[i] = random(5000);
    sizeOffsets[i] = random(0.5, 1.5);
    xPos[i] = random(width);
    yPos[i] = random(height);
  //Assign random bright colours for the chaotic state
    chaoticColors[i] = color(random(200, 255), random(0, 255), random(0, 255));
  }
}

//Event is triggered when a new camera frame is ready
void captureEvent(Capture video) {
  if (video.available()) video.read(); //Read the latest camera frame to show live feed
}

//Cycle through shape types when the mouse is pressed
void mousePressed() {
  shapeIndex = (shapeIndex + 1) % shapes.length; //Loop through available shape types
}

//  - DRAW LOOP - Main draw loop for video, audio and colour
void draw() {
  background(0);
  
  //If video is not ready, display fallback text
  if (!video.available()) {
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(20);
  text("Video feed not available", width/2, height/2);
  return; //Stop draw loop
  } 
  
   //If video is ready, proceed with rendering
  video.read();
  video.loadPixels();

  //Analyse the current microphone input level
  float volume = 0;
  for (int i = 0; i < in.bufferSize(); i++) { //Scale up waveform
    volume += abs(in.left.get(i)); //Add up the absolute amplitudes of the audio samples
  }
  volume /= in.bufferSize(); //Average the summed amplitudes to get the overall loudness of the mic input

  //Calculate transition speed based on input volume.
  float tSpeed = constrain(map(volume, 0, 0.2, 0, 1), 0, 1);
  
  //Map microphone volume to shape motion speed
  float motionSpeed = lerp(calmSpeed, chaoticSpeed, tSpeed); 
  
  //Draw all noise-based shapes
  for (int i = 0; i < numShapes; i++) {
    //Move each shape through the perlin noise field
    xNoise[i] += motionSpeed;
    yNoise[i] += motionSpeed;
    //Each shape's x and y position move according to Perlin noise
    float chaoticX = noise(xNoise[i]) * width; 
    float chaoticY = noise(yNoise[i]) * height;
    //Interpolate between current position and new target
    //Each shape is interpolated with 0.2 (20%) easing 
    xPos[i] = lerp(xPos[i], chaoticX, 0.2);
    yPos[i] = lerp(yPos[i], chaoticY, 0.2); 
    
    //Apply shape warping effect as mouse moves
    //Each shape is slightly pulled toward the mouse by amount variable
    float warpOffsetX = (mouseX - xPos[i]) * warpAmount;
    float warpOffsetY = (mouseY - yPos[i]) * warpAmount;
    float x = xPos[i] + warpOffsetX; //Apply noise movement and warp effect to x
    float y = yPos[i] + warpOffsetY;
    
    //Map shape size to distance from the mouse
    float d = dist(mouseX, mouseY, x, y);
    //Distance used to scale size mapping
    float maxDistance = dist(0, 0, width/2, height/2);
    //Final size of shapes
    //Closer shapes are smaller, farther shapes are larger, and shapes vary in random sizes
    float size = constrain(map(d, 0, maxDistance, 4, shapeScale*2) * sizeOffsets[i], 3, shapeScale*2);

    //Shape colours
    //Fill 'calm' state shapes with video pixels
    //Map each shape's screen coordinate to a pixel in the video feed
    int vidX = int(map(x, 0, width, 0, video.width-1));
    int vidY = int(map(y, 0, height, 0, video.height-1)); 
    int loc = vidX + vidY * video.width;
    color calmColor = video.pixels[loc]; //Pick pixel from camera feed
    //Interpolates between calm and chaotic colours at transition speed
    color c = lerpColor(calmColor, chaoticColors[i], tSpeed);
    
     //Map microphone volume to overall brightness
    float brightnessFactor = constrain(map(tSpeed, 0, 1, minBrightness, maxBrightness), minBrightness, maxBrightness);
    //Extract RGB channels and apply brightness based on volume
    float alpha = map(d, 0, maxDistance, 255, 40);
    float r = red(c) * brightnessFactor;
    float g = green(c) * brightnessFactor;
    float b = blue(c) * brightnessFactor;
    
    //Render final shape
    fill(r, g, b, alpha);
    drawShape(x, y, size);
    
    
    //Map microphone volume to oscillator output
    float freq = lerp(calmFreq, chaoticFreq, tSpeed);
    osc.setFrequency(freq); //Call frequency
    //Set the oscillator's volume output within a range
    osc.setAmplitude(constrain(tSpeed, 0.05, 0.2));
   
   
    //Cycle text instructions to fade and follow the mouse
  if (textAlpha < 255) {
    textAlpha += fadeSpeed; //Increase opacity each frame
    textAlpha = min(textAlpha, 255); //Stop at full opacity
  }
  //Switch text prompts based on cycle interval
  if (millis() - lastCycle > cycleInterval) {
    //instructionIndex increases between 1 and entire length of array
    instructionIndex = (instructionIndex + 1) % instructionsArray.length;
    currentInstruction = instructionsArray[instructionIndex]; //Update the message each loop
    textAlpha = 0; //Restart fade for new message
    lastCycle = millis();
  }
  //Draw instruction text following mouse
  fill(255, textAlpha); //White text
  textAlign(CENTER);
  textSize(20);
  text(currentInstruction, mouseX, mouseY - 50); //Above mouse
  }
 }
 
 // - STAR SHAPE - Define star shape drawing function
 void star(float x, float y, float radius1, float radius2, int npoints) {
  float angle = TWO_PI / npoints;
  float halfAngle = angle / 2.0;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius2;
    float sy = y + sin(a) * radius2;
    vertex(sx, sy);
    sx = x + cos(a + halfAngle) * radius1;
    sy = y + sin(a + halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

 // - SHAPE INDEX - Draw ellipse, rect and star shapes according to the selected type
//Draw shapes with all animations and functions applied
void drawShape(float x, float y, float size) {
  switch(shapes[shapeIndex]) {
    case "ellipse": ellipse(x, y, size, size); break;
    case "rect": rect(x, y, size/2, size/2); break;
    case "star": star(x, y, size*0.25, size*0.375, 5); break;
  }
}
