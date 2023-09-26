/*
* Developed by Zander Ruiz
*/

import processing.video.*;

Capture cam;
int birdX;
int birdY;
PImage flappyBird;

PImage pipe;
ArrayList<Point> pipeLocations = new ArrayList<Point>();
ArrayList<Boolean> pipeScored = new ArrayList<Boolean>();

boolean alive;
PImage gameOver;

int score;

float easing = 0.1;

void setup() {
  size(640, 480);
  frameRate(60);
  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    setup();
  } 
  else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    // The camera can be initialized directly using an
    // element from the array returned by list():
    cam = new Capture(this, cameras[2]);
    cam.start();
  }
  
  // Set up bird
  flappyBird = loadImage("flappybird.png");
  
  // Set up initial pipe
  pipe = loadImage("pipes.png");
  pipeLocations.add(new Point(width - pipe.width/2, height/2 + int(random(-150, 150))));
  pipeScored.add(false);
  
  alive = true;
  gameOver = loadImage("gameover.png");
  
  score = 0;
  
  noStroke();
  
  textFont(createFont("Arial", 30, true), 30);
}


// Light tracking
void draw() {
  // Draw the webcam image
  if (cam.available()) {
    cam.read();
  }
  
  imageMode(CORNER);
  image(cam, 0, 0);
  
  imageMode(CENTER);
  
  boolean redFound = scanForRed();
  
  if (redFound) {
    // Track flappy bird here
    image(flappyBird, birdX, birdY);
  }
  
  // Pipes
  for (int i = 0; i < pipeLocations.size(); i++) {
    int pipeX = pipeLocations.get(i).x;
    int pipeY = pipeLocations.get(i).y;
    
    image(pipe, pipeX, pipeY);
    
    boolean pipePassedBird = pipeX <= birdX - (flappyBird.width/2 + pipe.width/2);
    if (alive && !pipeScored.get(i) && pipePassedBird) {
      score++;
      pipeScored.set(i, true);
    }
     
    if (alive && redFound) {
      if (detectCollision(pipe, pipeX, pipeY)) {
        alive = false;
      }
      
      pipeLocations.get(i).x -= 1;
    }
  }
  
  // Delete/create new pipes
  if (pipeLocations.get(0).x < -pipe.width/2) {
    pipeLocations.remove(0);
    pipeScored.remove(0);
  }
  
  if (pipeLocations.get(pipeLocations.size() - 1).x < width - (pipe.width * 2)) {
    pipeLocations.add(new Point(width + pipe.width/2, height/2 + int(random(-150, 150))));
    pipeScored.add(false);
  }
  
  text("Score: " + score, 10, 30);
  
  if (!alive) {
    image(gameOver, width/2, height/2);
  }
}

/**
 * Scans the video feed for the presence of a red object and tracks it.
 * 
 * @return true if a red object is found and tracking is successful, false otherwise.
 */
boolean scanForRed() {
  
  colorMode(RGB, 255, 255, 255); 
  
  for (int y = 0; y < height; y += 10) { //loops through the left side
    for (int x = 0; x < width; x += 10) {
      color pixColor = cam.get(x, y);
      
      if (red(pixColor) > 180 && green(pixColor) <= 80 && blue(pixColor) <= 80) {
        // Easing:    
        int dx = x - birdX;
        birdX += dx * easing;
        
        int dy = y - birdY;
        birdY += dy * easing;
        
        return true;
      }
    }
  }
  return false;
}

/**
 * Detects collisions between the bird and pipes.
 * 
 * @param pipe The pipe image.
 * @param pipeX The X-coordinate of the pipe.
 * @param pipeY The Y-coordinate of the pipe.
 * @return true if a collision is detected, false otherwise.
 */
boolean detectCollision(PImage pipe, int pipeX, int pipeY) { 
  // Go through pixels in flappy bird
  for (int x = 0; x < flappyBird.width; x++) {
    for (int y = 0; y < flappyBird.height; y++) {
      color birdPixel = flappyBird.get(x, y); // Get color at pixel location
      
      // Check if the pixel in flappy bird is non-transparent
      if (alpha(birdPixel) > 0) {
        int absX = x + birdX - flappyBird.width/2;  // Adjusted for the position of bird
        int absY = y + birdY - flappyBird.height/2;
        
        // Check if the absolute pixel coordinates are within image2's boundaries
        if (absX >= pipeX - pipe.width/2 && absX < pipeX + pipe.width/2 &&
            absY >= pipeY - pipe.height/2 && absY < pipeY + pipe.height/2) {
          color pipePixel = pipe.get(absX - pipeX + pipe.width/2, absY - pipeY + pipe.height/2);
          
          // Check if the corresponding pixel in image2 is also non-transparent
          if (alpha(pipePixel) > 0) {
            return true;  // Collision detected
          }
        }
      }
    }
  }
  
  return false;  // No collision detected
}

class Point {
  int x;
  int y;
  
  public Point(int x, int y) {
    this.x = x;
    this.y = y;
  }
}
