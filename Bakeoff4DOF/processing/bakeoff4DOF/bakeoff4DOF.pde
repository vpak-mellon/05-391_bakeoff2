import java.util.ArrayList;
import java.util.Collections;
import processing.sound.*;

//these are variables you should probably leave alone
int index = 0; //starts at zero-ith trial
float border = 0; //some padding from the sides of window, set later
int trialCount = 10; //WILL BE MODIFIED FOR THE BAKEOFF
 //this will be set higher for the bakeoff
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 1.0f; //for every error, add this value to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false; //is the user done

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

// DGUO3 NEW GLOBALs
boolean dragging = false;
float dragOffsetX = 0;
float dragOffsetY = 0;
boolean rotatingByRing = false;
float pressX, pressY;

// --- Sound ---:
SoundFile correct;
boolean canPlaySound;

//These variables are for my example design. Your input code should modify/replace these!
float logoX = 500;
float logoY = 500;
float logoZ = 50f;
float logoRotation = 0;

private class Destination
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Destination> destinations = new ArrayList<Destination>();

void setup() {
  size(1000, 800);  
  rectMode(CENTER);
  textFont(createFont("Arial", inchToPix(.3f))); //sets the font to Arial that is 0.3" tall
  textAlign(CENTER);
  rectMode(CENTER); //draw rectangles not from upper left, but from the center outwards
  
  //don't change this! 
  border = inchToPix(2f); //padding of 1.0 inches
  
  // Load sound:
  correct = new SoundFile(this, "correct.mp3");
  canPlaySound = true;

  println("creating "+trialCount + " targets");
  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Destination d = new Destination();
    d.x = random(border, width-border); //set a random x with some padding
    d.y = random(border, height-border); //set a random y with some padding
    d.rotation = random(0, 360); //random rotation between 0 and 360
    int j = (int)random(20);
    d.z = ((j%12)+1)*inchToPix(.25f); //increasing size from .25 up to 3.0" 
    destinations.add(d);
    println("created target with " + d.x + "," + d.y + "," + d.rotation + "," + d.z);
  }

  Collections.shuffle(destinations); // randomize the order of the button; don't change this.
}

void is_correct_state() {
  if (!userDone && trialIndex < trialCount) {
    Destination d = destinations.get(trialIndex);
    boolean closeDist = dist(d.x, d.y, logoX, logoY) < inchToPix(.05f);
    boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logoRotation) <= 5;
    boolean closeZ = abs(d.z - logoZ) < inchToPix(.1f);
    
    if (closeDist && closeRotation && closeZ)
      background(0, 255, 255); // neon cyan - all correct
    else if (closeRotation && closeZ)
      background(255, 0, 255); // neon pink - rotation + size correct
    else
      background(40);
  }
}

float angleDifference(float current, float target) {
  float diff = (target - current) % 90;
  if (diff < -45) diff += 90;
  if (diff > 45) diff -= 90;
  return diff;
}

void rotation_ring() {
  if (!userDone && trialIndex < trialCount) {
    Destination d = destinations.get(trialIndex);
    float ringRadius = logoZ / 2 * sqrt(2) + 30;
    
    // Current size ring - neon yellow
    noFill();
    stroke(255, 255, 0);
    strokeWeight(2);
    ellipse(logoX, logoY, ringRadius * 2, ringRadius * 2);
    
    // Target size ring - neon green
    float targetRingRadius = d.z / 2 * sqrt(2) + 30;
    stroke(0, 255, 0);
    strokeWeight(2);
    ellipse(logoX, logoY, targetRingRadius * 2, targetRingRadius * 2);
    
    // Current rotation indicator (blue dot) - on yellow ring
    float curAngle = radians(logoRotation);
    float curX = logoX + cos(curAngle) * ringRadius;
    float curY = logoY + sin(curAngle) * ringRadius;
    fill(60, 60, 255);
    noStroke();
    ellipse(curX, curY, 20, 20);
    
    // Target rotation indicator (red X) - on green ring
    float diff = angleDifference(logoRotation, d.rotation);
    float targetVisual = logoRotation + diff;
    float targAngle = radians(targetVisual);
    float targX = logoX + cos(targAngle) * targetRingRadius;
    float targY = logoY + sin(targAngle) * targetRingRadius;
    stroke(255, 0, 0);
    strokeWeight(5);
    float xSize = 12;
    line(targX - xSize, targY - xSize, targX + xSize, targY + xSize);
    line(targX - xSize, targY + xSize, targX + xSize, targY - xSize);
    noStroke();
    
    // Draw arc between them
    stroke(255, 255, 0, 100);
    strokeWeight(3);
    noFill();
    if (diff > 0)
      arc(logoX, logoY, ringRadius * 2, ringRadius * 2, curAngle, curAngle + radians(diff));
    else
      arc(logoX, logoY, ringRadius * 2, ringRadius * 2, curAngle + radians(diff), curAngle);
  }
}

void draw() {

  background(40); //background is dark grey
  
  is_correct_state();
  
  fill(200);
  noStroke();

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchToPix(.4f));
    text("User had " + errorCount + " error(s)", width/2, inchToPix(.4f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per destination", width/2, inchToPix(.4f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per destination inc. penalty", width/2, inchToPix(.4f)*4);
    return;
  }

  //===========DRAW DESTINATION SQUARES=================
  for (int i=trialIndex; i<trialCount; i++) // reduces over time
  {
    pushMatrix();
    Destination d = destinations.get(i); //get destination trial
    translate(d.x, d.y); //center the drawing coordinates to the center of the destination trial
    
    rotate(radians(d.rotation)); //rotate around the origin of the Ddestination trial
    noFill();
    strokeWeight(3f);
    if (trialIndex==i) {
      stroke(255, 0, 0);
      strokeWeight(5f);
      rect(0, 0, d.z, d.z);
    }
    else {
      stroke(128, 128, 128, 128);
      rect(0, 0, d.z, d.z);
    }
    popMatrix();
  }

  //===========DRAW LOGO SQUARE=================
  pushMatrix();
  translate(logoX, logoY);
  rotate(radians(logoRotation));
  noStroke();
  fill(60, 60, 192);
  rect(0, 0, logoZ, logoZ);
  // Light boundary showing draggable area
  stroke(255, 255, 255, 60);
  strokeWeight(1);
  noFill();
  rect(0, 0, logoZ + 20, logoZ + 20);
  popMatrix();
  
  // rotation ring
  rotation_ring();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  scaffoldControlLogic();
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
  
  if (!userDone && trialIndex < trialCount) {
    Destination d = destinations.get(trialIndex);
    stroke(255, 255, 0, 128);
    strokeWeight(8);
    line(logoX, logoY, d.x, d.y);
    noStroke();
  }

  // Center dots - drawn last so always on top
  if (!userDone && trialIndex < trialCount) {
    Destination d = destinations.get(trialIndex);
    fill(0, 255, 0);
    noStroke();
    ellipse(d.x, d.y, 20, 20);
    
    fill(255, 255, 0);
    noStroke();
    ellipse(logoX, logoY, 20, 20);
  }
}

//my example design for control, which is terrible
void scaffoldControlLogic()
{
  //upper left corner, rotate counterclockwise
  text("CCW", inchToPix(.4f), inchToPix(.4f));
  if (mousePressed && dist(0, 0, mouseX, mouseY)<inchToPix(.8f))
    logoRotation--;

  //upper right corner, rotate clockwise
  text("CW", width-inchToPix(.4f), inchToPix(.4f));
  if (mousePressed && dist(width, 0, mouseX, mouseY)<inchToPix(.8f))
    logoRotation++;

  //lower left corner, decrease Z
  text("-", inchToPix(.4f), height-inchToPix(.4f));
  if (mousePressed && dist(0, height, mouseX, mouseY)<inchToPix(.8f))
    logoZ = constrain(logoZ-inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone!

  //lower right corner, increase Z
  text("+", width-inchToPix(.4f), height-inchToPix(.4f));
  if (mousePressed && dist(width, height, mouseX, mouseY)<inchToPix(.8f))
    logoZ = constrain(logoZ+inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone! 

  //left middle, move left
  text("left", inchToPix(.4f), height/2);
  if (mousePressed && dist(0, height/2, mouseX, mouseY)<inchToPix(.8f))
    logoX-=inchToPix(.02f);

  text("right", width-inchToPix(.4f), height/2);
  if (mousePressed && dist(width, height/2, mouseX, mouseY)<inchToPix(.8f))
    logoX+=inchToPix(.02f);

  text("up", width/2, inchToPix(.4f));
  if (mousePressed && dist(width/2, 0, mouseX, mouseY)<inchToPix(.8f))
    logoY-=inchToPix(.02f);

  text("down", width/2, height-inchToPix(.4f));
  if (mousePressed && dist(width/2, height, mouseX, mouseY)<inchToPix(.8f))
    logoY+=inchToPix(.02f);
}

void drag_motion() {
  // Check if click is on the logo square
  // We need to account for rotation, so transform mouse into logo's local space
  float dx = mouseX - logoX;
  float dy = mouseY - logoY;
  float cosR = cos(radians(-logoRotation));
  float sinR = sin(radians(-logoRotation));
  float localX = dx * cosR - dy * sinR;
  float localY = dx * sinR + dy * cosR;
  
  if (abs(localX) < logoZ / 2 + 10 && abs(localY) < logoZ / 2 + 10) {
    dragging = true;
    dragOffsetX = logoX - mouseX;
    dragOffsetY = logoY - mouseY;
  }
}


void mousePressed() {
  if (startTime == 0) {
    startTime = millis();
    println("time started!");
  }
  pressX = mouseX;
  pressY = mouseY;
  
  if (!userDone && trialIndex < trialCount) {
    // Check rotation handle
    float ringRadius = logoZ / 2 * sqrt(2) + 30;
    float curAngle = radians(logoRotation);
    float curX = logoX + cos(curAngle) * ringRadius;
    float curY = logoY + sin(curAngle) * ringRadius;
    if (dist(mouseX, mouseY, curX, curY) < 20) {
      rotatingByRing = true;
      return;
    }
  }
  
  drag_motion();
}

// Change cursor based on available movements
void mouseMoved() {
  // Check if click is on the logo square
  // We need to account for rotation, so transform mouse into logo's local space
  float dx = mouseX - logoX;
  float dy = mouseY - logoY;
  float cosR = cos(radians(-logoRotation));
  float sinR = sin(radians(-logoRotation));
  float localX = dx * cosR - dy * sinR;
  float localY = dx * sinR + dy * cosR;
  
  // Check rotation handle
  float ringRadius = logoZ / 2 * sqrt(2) + 30;
  float curAngle = radians(logoRotation);
  float curX = logoX + cos(curAngle) * ringRadius;
  float curY = logoY + sin(curAngle) * ringRadius;
  
  if (abs(localX) < logoZ / 2 + 10 && abs(localY) < logoZ / 2 + 10) { // in square
    cursor(MOVE); // = can drag square
  } else if (dist(mouseX, mouseY, curX, curY) < 20) { // in ring handle
    cursor(HAND); // = can rotate by ring
  } else {
    cursor(ARROW); // = not able to drag or rotate
  }
}

void mouseDragged() {
  if (rotatingByRing) {
    // Rotation from angle
    float angle = atan2(mouseY - logoY, mouseX - logoX);
    logoRotation = degrees(angle);
    
    // Size from distance - map mouse distance to logoZ
    // Target green ring is at: d.z / 2 * sqrt(2) + 30
    // When mouse is ON the green ring, logoZ should equal d.z
    Destination d = destinations.get(trialIndex);
    float mouseDist = dist(mouseX, mouseY, logoX, logoY);
    float newZ = (mouseDist - 30) * 2 / sqrt(2);
    logoZ = constrain(newZ, .01, inchToPix(4f));
  } else if (dragging) {
    logoX = mouseX + dragOffsetX;
    logoY = mouseY + dragOffsetY;
  }
  
  if (checkForSuccess() && canPlaySound) {
    correct.play(); // play sound when correct position
    canPlaySound = false;
  }
  
  if (!checkForSuccess()) {
    canPlaySound = true;
  }
}

void mouseReleased() {
  boolean wasInteracting = dragging || rotatingByRing;
  boolean didMove = dist(pressX, pressY, mouseX, mouseY) > 3; // tiny threshold
  dragging = false;
  rotatingByRing = false;
  
  // Submit if it was a click (not a drag) anywhere
  if (!didMove) {
    if (userDone == false && !checkForSuccess())
      errorCount++;
    trialIndex++;
    if (trialIndex == trialCount && userDone == false) {
      userDone = true;
      finishTime = millis();
    }
  }
}

//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
  Destination d = destinations.get(trialIndex);  
  boolean closeDist = dist(d.x, d.y, logoX, logoY)<inchToPix(.05f); //has to be within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logoRotation)<=5;
  boolean closeZ = abs(d.z - logoZ)<inchToPix(.1f); //has to be within +-0.1"  

  println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logoX + "/" + logoY +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(d.rotation, logoRotation)+")");
  println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logoZ +")");
  println("Close enough all: " + (closeDist && closeRotation && closeZ));

  return closeDist && closeRotation && closeZ;
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2)
{
  double diff=abs(a1-a2);
  diff%=90;
  if (diff>45)
    return 90-diff;
  else
    return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch)
{
  return inch*screenPPI;
}
