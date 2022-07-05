/*Before running this code install P5 and OpenCV for processing*/
import gab.opencv.*;
import org.opencv.core.Mat;
import org.opencv.core.Scalar;
import controlP5.*;
import processing.video.*;
import java.awt.*;
import processing.sound.*;

SoundFile jump;
SoundFile coin;
SoundFile start;
SoundFile end;
SoundFile dead;
SoundFile enemy;
SoundFile heal;
SoundFile attack;
SoundFile collect;
SoundFile damage;


PImage dst;

Scalar mLowerBound = new Scalar(0);
Scalar mUpperBound = new Scalar(0);
    
ControlP5 cp5;
int sliderMinHue=100;
int sliderMinSat=150;
int sliderMinVal=0;
int sliderMaxHue=140;
int sliderMaxSat=255;
int sliderMaxVal=255;
int sliderThreshold = 100;
int n_dilate = 5;
int n_erode = 2;

PImage img;
PImage result;
PImage wall;
PImage lava;
PImage spriteRight;
PImage spriteLeft;
PImage spriteUp;
PImage spriteDown;
PImage goal;
PImage goalOff;

PImage flySprite;
PImage collectableSprite;
PImage heartSprite;
PImage slimeSprite;

PImage attackSprite;

int flag = 1;
//NOTA: si el cuadro del juego es mas grande que tu pantalla, redimensiona la imagen


float[] blueValues = {100, 150,0,140,255,255,5,1}; //minHue, minSat, minVal, maxHue,maxSat,maxVal
float[] redValues = {0, 80,80,20,255,255,5,1};
float[] greenValues = {40, 80,30,80,255,255,5,1};
float[] yellowValues = {10, 80,150,35,255,255,5,1};
float[] blackValues = {0, 0,0,255,100,50,5,1};
float[] purpleValues = {130, 80,30,170,160,100,5,1};

float[] [] colorValues = {blueValues,redValues, greenValues,yellowValues,blackValues, purpleValues};


float playerX = 0;
float playerY = 0;
float playerVelocityY = 0;
float playerVelocityX = 0;
float playerSpeed = 3;
float playerJumpSpeed = -5;
float playerSizeX = 10;
float playerSizeY = 10;
float upKey;
float rightKey;
float downKey;
float leftKey;
boolean onGround;
float gravity = .1;
boolean busy = false;
boolean attacking = false;
int time;
float attackBoxX;
float attackBoxY;

int health = 3;
boolean playing = false;
boolean locked = true;//if the player can finish the level
boolean invincible = false;//so the player doesn't die instantly
int facing = 0;//0 = right, 1 = left, 2 = up, 3 = down

//timers
int previousTime = 0;
int elapsedTime;
int attackTime = 750;
int attackTimer = 0;
int invincibleTime = 2500;
int invincibleTimer = 0;




//Capture video;
OpenCV opencv;
OpenCV opencv_countours;
Capture video;


int lowerb = 50;
int upperb = 100;
Mat mask;

ArrayList<Contour> bluePolys;// blue collidable terrain
ArrayList<Contour> redPolys;// dangerous terrain
ArrayList<Contour> greenPolys;// player objective
ArrayList<Contour> yellowPolys;// collectables
Rectangle blackPoly;// player spawn
ArrayList<Contour> purplePolys; // enemies

ArrayList<Slime> slimes;
ArrayList<Fly> flies;
ArrayList<Collectable> collectables;
ArrayList<Heart> hearts;

IntList toDelete;//indexes to delete contours

//buttons
int rectX, rectY;      // Position of square button
int circleX, circleY;  // Position of circle button
int rectSize = 90;     // Diameter of rect
int circleSize = 93;   // Diameter of circle
color rectColor, circleColor, baseColor;
color rectHighlight, circleHighlight;
color currentColor;
boolean rectOver = false;
boolean circleOver = false;

boolean debug = true;

void setup() {
  //size(1386, 780);
  size(640, 480, P2D);
  result = new PImage();
  cp5 = new ControlP5(this);
  
  video = new Capture(this, 640, 480);
  jump = new SoundFile(this, "data/jump.wav");
  coin = new SoundFile(this, "coin.wav");
  start = new SoundFile(this, "data/start.wav");
  dead = new SoundFile(this, "data/dead.wav");
  end = new SoundFile(this, "data/win.wav");
  enemy = new SoundFile(this, "data/enemy_death.wav");
  heal = new SoundFile(this, "data/heal.wav");
  attack = new SoundFile(this, "data/slash.wav");
  collect = new SoundFile(this, "data/coin.wav");
  damage = new SoundFile(this, "data/damage.wav");
  
  wall = loadImage("data/brick.jpg");
  lava = loadImage("data/lava.jpg");
  spriteRight = loadImage("data/Right.png");
  spriteLeft = loadImage("data/Left.png");
  spriteUp = loadImage("data/Up.png");
  spriteDown = loadImage("data/Down.png");
  goal = loadImage("data/goal.jpg");
  goalOff = loadImage("data/goalOff.jpg");
  flySprite = loadImage("data/enemy2.png");
  slimeSprite = loadImage("data/enemy1.png");
  collectableSprite = loadImage("data/coin.png");
  heartSprite = loadImage("data/heart.png");
  attackSprite = loadImage("data/attack.png");
  
  
  surface.setResizable(true);
  
  video.start();
  
  
  //buttons
  rectColor = color(0);
  rectHighlight = color(51);
  circleColor = color(255);
  circleHighlight = color(204);
  baseColor = color(102);
  currentColor = baseColor;
  circleX = width-circleSize/2-10;
  circleY = height-circleSize/2-10;
  rectX = 10;
  rectY = height-rectSize-10;
  ellipseMode(CENTER);
  
  toDelete = new IntList();
     
  //video.start();
  
  slimes = new ArrayList<Slime>();
  flies = new ArrayList<Fly>();
  hearts = new ArrayList<Heart>();
  collectables = new ArrayList<Collectable>();
  
  
  

}

void draw() {
  
  elapsedTime = millis() - previousTime;
  previousTime = millis();
  
  
  noFill();
  strokeWeight(3);
  
  
  /////////////////////////////////////////////////////////////////////////// Game logic
  if(playing){
    
    //image(img, 0, 0);
    background(255, 204, 0);
    fill(5,0,0);
    stroke(0, 0, 0);
    
    if(health <= 0)
      Death();
     
    //playerVelocityY += gravity;
    playerVelocityY = (downKey - upKey) * playerSpeed;
    playerVelocityX = (rightKey - leftKey) * playerSpeed;
    
    float nextY = playerY + playerVelocityY;
    float nextX = playerX + playerVelocityX;
    
    
    for (Contour contour : bluePolys) {//collisions with walls
       if(polyRect(contour.getPolygonApproximation().getPoints(),nextX, nextY,playerSizeX, playerSizeY)){
         playerVelocityX = 0;
         playerVelocityY = 0;
       
       }
    }
    for (Contour contour : redPolys) {//collisions dangerous walls
       if(polyRect(contour.getPolygonApproximation().getPoints(),nextX, nextY,playerSizeX, playerSizeY)){

         Death();
       
       }
    }
    for (Contour contour : greenPolys) {//collisions goal
       if(polyRect(contour.getPolygonApproximation().getPoints(),nextX, nextY,playerSizeX, playerSizeY)){
         if(!locked){
           playerX = blackPoly.x;
           playerY = blackPoly.y;
           playing = false;
           end.play();
           hearts.clear();
           collectables.clear();
           slimes.clear();
           flies.clear();
           locked = true;
           clear();
           surface.setSize(640, 480);
         }
         else {
           playerVelocityX = 0;
           playerVelocityY = 0;
         }
       
       }
    }
    
    for(Heart hrt: hearts){
          if(hrt.active)
            if(rectRect(nextX, nextY, playerSizeX, playerSizeY, hrt.x, hrt.y, hrt.wid, hrt.heig))
              hrt.use();
    }
    for(Collectable clb: collectables){
      if(clb.active)
         if(rectRect(nextX, nextY, playerSizeX, playerSizeY, clb.x, clb.y, clb.wid, clb.heig))
              clb.use();
    }
    if(!invincible){
      for(Fly fl: flies){
          if(fl.active)
            if(rectRect(nextX, nextY, playerSizeX, playerSizeY, fl.x, fl.y, fl.wid, fl.heig))
                takeDamage();
        }
        for(Slime slm: slimes){
          if(slm.active)
           if(rectRect(nextX, nextY, playerSizeX, playerSizeY, slm.x, slm.y, slm.wid, slm.heig))
                takeDamage();
        }
    }
    else{
      invincibleTimer+= elapsedTime;
      if(invincibleTimer >= invincibleTime){
        invincible = false;
        invincibleTimer = 0;
      
      }
    }

    if(nextX > width || nextX < 0)
      playerVelocityX = 0;
    if(nextY > height || nextY < 0)
      playerVelocityY = 0;
    
    
    
    playerX += playerVelocityX;
    playerY += playerVelocityY;
     noStroke();
    beginShape();
    
    switch(facing){
      case 0: // right
        texture(spriteRight);
      break;
      case 1:
        texture(spriteLeft); 
      break;
      case 2:
        texture(spriteUp);
      break;
      case 3:
        texture(spriteDown);
      break;
    }
    vertex(playerX, playerY, 0,0);
    vertex(playerX + playerSizeX, playerY, spriteRight.width,0);
    vertex(playerX + playerSizeX, playerY+playerSizeY, spriteRight.width,spriteRight.height);
    vertex(playerX, playerY+playerSizeY, 0,spriteRight.height);
    endShape();
    
    if(attacking){
      beginShape();
      texture(attackSprite);
      switch(facing){
        case 0: // right
          attackBoxX = playerX + playerSizeX;
          attackBoxY = playerY;
        break;
        case 1:
          attackBoxX = playerX - playerSizeX;
          attackBoxY = playerY;
        break;
        case 2://up
          attackBoxX = playerX;
          attackBoxY = playerY-playerSizeY;
        break;
        case 3:
          attackBoxX = playerX;
          attackBoxY = playerY+playerSizeY;
        break;
      }
      vertex(attackBoxX, attackBoxY, 0,0);
      vertex(attackBoxX + playerSizeX, attackBoxY, attackSprite.width,0);
      vertex(attackBoxX + playerSizeX, attackBoxY+playerSizeY, attackSprite.width,attackSprite.height);
      vertex(attackBoxX, attackBoxY+playerSizeY, 0,attackSprite.height);
      endShape();
      noFill();
      
      
      for(Fly fl: flies){
        if(fl.active)
          if(rectRect(attackBoxX, attackBoxY, playerSizeX, playerSizeY, fl.x, fl.y, fl.wid, fl.heig))
              fl.die();
      }
      for(Slime slm: slimes){
        if(slm.active)
         if(rectRect(attackBoxX, attackBoxY, playerSizeX, playerSizeY, slm.x, slm.y, slm.wid, slm.heig))
              slm.die();
      }
     
      
      attackTimer+= elapsedTime;
      if(attackTimer >= attackTime){
        attacking = false;
        attackTimer = 0;
      
      }
    
    }
    

    
      
        //stroke(255, 255, 0);
        noStroke();
          
        //draw collision polygons
      
      
        for (Contour contour : bluePolys) { 
            
            
            
          textureWrap(REPEAT);
            
          beginShape();
          texture(wall);
          for (PVector point : contour.getPolygonApproximation().getPoints()) {
            vertex(point.x, point.y,point.x, point.y);
          }
          endShape();
            
        }
        for (Contour contour : redPolys) {
           
            
           
            
          beginShape();
          texture(lava);
          for (PVector point : contour.getPolygonApproximation().getPoints()) {
            vertex(point.x, point.y,point.x, point.y);
          }
          endShape();
            
        }
        for (Contour contour : greenPolys) {
          
            
            
            
          beginShape();
          if(locked)
            texture(goalOff);
          else
            texture(goal);
          for (PVector point : contour.getPolygonApproximation().getPoints()) {
            vertex(point.x, point.y,point.x, point.y);
          }
          endShape();
            
        }
        for(Heart hrt: hearts){
          if(hrt.active)
            hrt.Draw();
        }
        for(Collectable clb: collectables){
          if(clb.active){
            
            clb.Draw();
          }
        }
        for(Fly fl: flies){
          if(fl.active){
            fl.move();
            fl.Draw();
          }
        }
        for(Slime slm: slimes){
          if(slm.active){
              slm.update();
              if(slm.moving)
                slm.move();
              slm.Draw();
          }
        }
    
        /*beginShape();
        rect(yellowPoly.x,yellowPoly.y,yellowPoly.width,yellowPoly.height);
        endShape();*/
        fill(0,0,0);
      for(int i = 0; i< health; i++){//draw ui
        image(heartSprite,0+20*i,0,20,20);
      }
    
    
  }
  else{
    image(video, 0, 0 );

    noFill();
    update(mouseX, mouseY);
    
    
    if (rectOver) {
      fill(rectHighlight);
    } else {
      fill(rectColor);
    }
    stroke(255);
    rect(rectX, rectY, rectSize, rectSize);
    
   
    
    if (circleOver) {
      fill(circleHighlight);
    } else {
      fill(circleColor);
    }
    stroke(0);
    ellipse(circleX, circleY, circleSize, circleSize);
    
    textSize(16);
    fill(circleColor);
    text("test",40,height-50);
  
    fill(rectColor);
    text("take",width-73,height-50);
    
    noFill();
 }
    

}


void keyReleased()
{
  if (key == CODED)
  {
    if (keyCode == LEFT && leftKey == 1)
    {
      leftKey = 0;
      busy = false;
    }
    if (keyCode == RIGHT&& rightKey == 1)
    {
      rightKey = 0;
      busy = false;
    }
    if (keyCode == UP && upKey == 1)
    {
      upKey = 0;
      busy = false;
    }
    if (keyCode == DOWN && downKey == 1)
    {
      downKey = 0;
      busy = false;
    }
  }
}


void keyPressed()//inputs
{
   if (key == ' ' && attacking == false)
  {
    attacking = true;
    attack.play();
  }
   
  if (key == CODED)
  {
    if (keyCode == LEFT && busy == false)
    {
      leftKey = 1;
      busy = true;
      facing = 1;
    }
    if (keyCode == RIGHT && busy == false)
    {
      rightKey = 1;
      busy = true;
      facing = 0;
    }
    if (keyCode == UP && busy == false)
    {
      upKey = 1;
      busy = true;
      facing = 2;
    }
    if (keyCode == DOWN && busy == false)
    {
      downKey = 1;
      busy = true;
      facing = 3;
    }
  }
}

void mouseClicked() {
  if (!playing) {
     if (circleOver) {
       video.read();
       img = createImage(video.width, video.height, HSB);
       img.copy(video,  0,0, video.width,video.height,  0,0, video.width,video.height);
       calculatePolys();
       playing = true;
       start.play();
       //surface.setSize(640, 480);
      
    }
    if (rectOver) {
       img = loadImage("test8.jpeg");
       calculatePolys();
       playing = true;
       start.play();
       surface.setSize(img.width, img.height);
    }
    
  } 
  
}


// POLYGON/RECTANGLE
boolean polyRect(ArrayList<PVector> vertices, float rx, float ry, float rw, float rh) {

  // go through each of the vertices, plus the next
  // vertex in the list
  int next = 0;
  for (int current=0; current<vertices.size(); current++) {

    // get next vertex in list
    // if we've hit the end, wrap around to 0
    next = current+1;
    if (next == vertices.size()) next = 0;

    // get the PVectors at our current position
    // this makes our if statement a little cleaner
    PVector vc = vertices.get(current);    // c for "current"
    PVector vn = vertices.get(next);       // n for "next"

    // check against all four sides of the rectangle
    boolean collision = lineRect(vc.x,vc.y,vn.x,vn.y, rx,ry,rw,rh);
    if (collision) return true;

    // optional: test if the rectangle is INSIDE the polygon
    // note that this iterates all sides of the polygon
    // again, so only use this if you need to
   // boolean inside = polygonPoint(vertices, rx,ry);
    //if (inside) return true;
  }

  return false;
}
// RECTANGLE/RECTANGLE
boolean rectRect(float x1,float y1, float w1, float h1, float x2,float y2, float w2, float h2){
    
  // check if the line has hit any of the rectangle's sides
  // uses the Line/Line function below
  boolean left =   lineRect(x1, y1, x1, y1+h1, x2, y2, w2, h2);
  boolean right =  lineRect(x1+w1, y1, x1+w1, y1+h1, x2, y2, w2, h2);
  boolean top =   lineRect(x1, y1, x1+w1, y1, x2, y2, w2, h2);
  boolean bottom = lineRect(x1, y1+h1, x1+w1, y1+h1, x2, y2, w2, h2);

  // if ANY of the above are true,
  // the line has hit the rectangle
  if (left || right || top || bottom) {
    return true;
  }
  return false;
  
}
// LINE/RECTANGLE
boolean lineRect(float x1, float y1, float x2, float y2, float rx, float ry, float rw, float rh) {

  // check if the line has hit any of the rectangle's sides
  // uses the Line/Line function below
  boolean left =   lineLine(x1,y1,x2,y2, rx,ry,rx, ry+rh);
  boolean right =  lineLine(x1,y1,x2,y2, rx+rw,ry, rx+rw,ry+rh);
  boolean top =    lineLine(x1,y1,x2,y2, rx,ry, rx+rw,ry);
  boolean bottom = lineLine(x1,y1,x2,y2, rx,ry+rh, rx+rw,ry+rh);

  // if ANY of the above are true,
  // the line has hit the rectangle
  if (left || right || top || bottom) {
    return true;
  }
  return false;
}

// LINE/LINE
boolean lineLine(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {

  // calculate the direction of the lines
  float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
  float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));

  // if uA and uB are between 0-1, lines are colliding
  if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
    return true;
  }
  return false;
}

void captureEvent(Capture c) {
  c.read();
}

void update(int x, int y) {
  if ( overCircle(circleX, circleY, circleSize) ) {
    circleOver = true;
    rectOver = false;
  } else if ( overRect(rectX, rectY, rectSize, rectSize) ) {
    rectOver = true;
    circleOver = false;
  } else {
    circleOver = rectOver = false;
  }
}

boolean overCircle(int x, int y, int diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}
boolean overRect(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

void Death(){
     playerX = blackPoly.x;
     playerY = blackPoly.y;
     playerVelocityX = 0;
     playerVelocityY = 0;
     health = 3;
     dead.play();
     
     locked = true;
     
    for(Heart hrt: hearts){
        hrt.active = true;
    }
    for(Collectable clb: collectables){
      clb.active = true;
    }
    
    for(Fly fl: flies){
      fl.active = true;
      fl.x = fl.originalX;
      fl.y = fl.originalY;
    }
    for(Slime slm: slimes){
      slm.active = true;
      slm.x = slm.originalX;
      slm.y = slm.originalY;
    }
   
     
}

void takeDamage() {
  damage.play();
  health--;
  invincible = true;

}

void calculatePolys(){
  opencv = new OpenCV(this, img);
  opencv.useColor(HSB);
  
  opencv_countours = new OpenCV(this,img);
  
  for(int i = 0;i<6;i++){
    
    mLowerBound.val[0]= colorValues[i][0];//sliderMinHue;
    mUpperBound.val[0]= colorValues[i][3];//sliderMaxhue
    mLowerBound.val[1]= colorValues[i][1];//sliderMinSat;
    mUpperBound.val[1]= colorValues[i][4];//sliderMaxSat;
    mLowerBound.val[2]= colorValues[i][2];//sliderMinVal;
    mUpperBound.val[2]= colorValues[i][5];//sliderMaxVal;
    
    mask = opencv.matHSV.clone();
    org.opencv.core.Core.inRange(opencv.matHSV, mLowerBound, mUpperBound, mask); //image binarizarion using H,S,V channels at the same time
    
    opencv.toPImage(mask,result); 
    opencv.loadImage(img);
    
    //image(img, 0, 0);
    
    //-------------------------------------------------------
    //the opencv wrapper for processing only allows to use inRange in a single channell.
    //  opencv.setGray(opencv.getH().clone());
    //  opencv.inRange(sliderMinHue, sliderMaxHue); 
    //image(opencv.getOutput(), 3*width/4, 3*height/4, width/4,height/4);
    //-------------------------------------------------------
    //image(opencv.getSnapshot(mask), 3*width/4, 3*height/4, width/4,height/4);
    
     opencv_countours.loadImage(opencv.getSnapshot(mask));//find shape after color detection
     for(int j=0; j <n_erode; j++)   opencv_countours.erode();  
     for(int j=0; j <n_dilate; j++)   opencv_countours.dilate(); 
     
     dst = opencv_countours.getOutput();
     
     switch(i){//fill polys and pShapes //NOTA: Aqui se llenan las estructuras de datos con las formas detectadas, es donde se deberian detectar las formas
       case 0:
         bluePolys = opencv_countours.findContours();
         break;
       case 1:
         redPolys = opencv_countours.findContours();
         break;
       case 2:
         greenPolys = opencv_countours.findContours();
         break;
       case 3:
         yellowPolys = opencv_countours.findContours();
         for(Contour contour : yellowPolys){
           Rectangle temp = contour.getBoundingBox();
           if(temp.height > temp.width){
             hearts.add(new Heart(temp.x,temp.y, 0,temp.width ));
           }
           else{
             collectables.add(new Collectable(temp.x,temp.y, temp.height,0 ));
           }
           
         }
         break;
       case 4:
         blackPoly = opencv_countours.findContours().get(0).getBoundingBox();
         playerX = blackPoly.x;
         playerY = blackPoly.y;
         playerSizeX = blackPoly.width;
         playerSizeY = blackPoly.height;
         break;
       case 5:
         purplePolys = opencv_countours.findContours();
         for(Contour contour : purplePolys){
           Rectangle temp = contour.getBoundingBox();
           if(temp.height > temp.width){
             flies.add(new Fly(temp.x,temp.y, 0,temp.width ));
           }
           else{
             slimes.add(new Slime(temp.x,temp.y, temp.height,0 ));
           }
           
         }
         break;
     }
     
     //image(dst, 0, 3*height/4,width/4,height/4);
  }
}

class Poly { 
  Contour contour; 
  boolean active = true;
} 

class Entity {
  float x;
  float y;
  float originalX;
  float originalY;
  float wid;
  float heig;
  boolean active = true;
  Entity(float X, float Y, float H, float W){
    x = X;
    y = Y;
    originalX = X;
    originalY = Y;
    wid = W;
    heig = H;
  }
}

class Slime extends Entity {
  float speed, velocityY,velocityX, directionX, directionY, magnitude;
  int movementTimer = 0;
  int movementTime = 650;
  int stopTimer = 0;
  int stopTime = 1500;
  boolean moving = false;
  Slime(float x, float y, float H, float W) {
     super(x, y, H, H*(collectableSprite.width/collectableSprite.height)); //calculate height to keep aspect ratio rectangle
     speed = 5;
  }
  
  void Draw(){
    beginShape();
    texture(slimeSprite);
    vertex(x, y, 0,0);
    vertex(x + wid, y, slimeSprite.width,0);
    vertex(x + wid, y+heig, slimeSprite.width,slimeSprite.height);
    vertex(x, y+heig, 0,slimeSprite.height);
    endShape();
  }
  
  void die(){
    enemy.play();
    this.active = false;
  }
  
  void update(){
    if(moving){
      movementTimer+= elapsedTime;
      if(movementTimer >= movementTime){
        moving = false;
        movementTimer = 0;
      
      }
    }
    else{
      stopTimer+= elapsedTime;
      if(stopTimer >= stopTime){
        moving = true;
        stopTimer = 0;
      
      }
    }
  }
  
  void move(){
  //calculate vector
    directionX = playerX - x;
    directionY = playerY - y;
    magnitude = sqrt(directionX * directionX + directionY * directionY);
    directionX = directionX/magnitude;
    directionY = directionY/magnitude;
    
    velocityY = directionY * speed;
    velocityX = directionX * speed;
    
    float nextY = y + velocityY;
    float nextX = x + velocityX;
    
    
    for (Contour contour : bluePolys) {//collisions with walls
       if(polyRect(contour.getPolygonApproximation().getPoints(),nextX, nextY,wid, heig)){
         velocityX = 0;
         velocityY = 0;
       
       }
    }
    for (Contour contour : redPolys) {//collisions dangerous walls
       if(polyRect(contour.getPolygonApproximation().getPoints(),nextX, nextY,wid, heig)){

         this.die();
       
       }
    }
    for (Contour contour : greenPolys) {//collisions goal
       if(polyRect(contour.getPolygonApproximation().getPoints(),nextX, nextY,wid, heig)){
         
         velocityX = 0;
         velocityY = 0;
         
       
       }
    }
    
    if(nextX > width || nextX < 0)
      velocityX = 0;
    if(nextY > height || nextY < 0)
      velocityY = 0;
    
    
    
    x += velocityX;
    y += velocityY;
    
  
  }
    

}
class Fly extends Entity {
  float speed, velocityY,velocityX, directionX, directionY, magnitude;
  Fly(float x, float y, float H, float W) {
    super(x, y, W/(heartSprite.width/heartSprite.height), W);//calculate height to keep aspect ratio triangle
    speed = 1.5;
  }
  
  void Draw(){
    beginShape();
    texture(flySprite);
    vertex(x, y, 0,0);
    vertex(x + wid, y, flySprite.width,0);
    vertex(x + wid, y+heig, flySprite.width,flySprite.height);
    vertex(x, y+heig, 0,flySprite.height);
    endShape();
  }
  
  void die(){
    enemy.play();
    this.active = false;
  }
  
  void move(){
  //calculate vector
    directionX = playerX - x;
    directionY = playerY - y;
    magnitude = sqrt(directionX * directionX + directionY * directionY);
    directionX = directionX/magnitude;
    directionY = directionY/magnitude;
    
    velocityY = directionY * speed;
    velocityX = directionX * speed;
    
    float nextY = y + velocityY;
    float nextX = x + velocityX;
    
    
    for (Contour contour : bluePolys) {//collisions with walls
       if(polyRect(contour.getPolygonApproximation().getPoints(),nextX, nextY,wid, heig)){
         velocityX = 0;
         velocityY = 0;
       
       }
    }
    for (Contour contour : redPolys) {//collisions dangerous walls
       if(polyRect(contour.getPolygonApproximation().getPoints(),nextX, nextY,wid, heig)){

         this.die();
       
       }
    }
    for (Contour contour : greenPolys) {//collisions goal
       if(polyRect(contour.getPolygonApproximation().getPoints(),nextX, nextY,wid, heig)){
         
         velocityX = 0;
         velocityY = 0;
         
       
       }
    }
    
    if(nextX > width || nextX < 0)
      velocityX = 0;
    if(nextY > height || nextY < 0)
      velocityY = 0;
    
    
    
    x += velocityX;
    y += velocityY;
    
  
  }

}

class Heart extends Entity {
  Heart(float x, float y, float H, float W) {
    
    super(x, y, W/(heartSprite.width/heartSprite.height), W);//calculate height to keep aspect ratio triangle
  }
  
  void Draw(){
    beginShape();
    texture(heartSprite);
    vertex(x, y, 0,0);
    vertex(x + wid, y, heartSprite.width,0);
    vertex(x + wid, y+heig, heartSprite.width,heartSprite.height);
    vertex(x, y+heig, 0,heartSprite.height);
    endShape();
  }
  
  void use(){
    heal.play();
    if(health < 3)
      health = health+1;
      
    active = false;
  }
}

class Collectable extends Entity {
  Collectable(float x, float y, float H, float W) {
    super(x, y, H, H*(collectableSprite.width/collectableSprite.height)); //calculate height to keep aspect ratio rectangle
  }
  
  void Draw(){
    beginShape();
    texture(collectableSprite);
    vertex(x, y, 0,0);
    vertex(x + wid, y, collectableSprite.width,0);
    vertex(x + wid, y+heig, collectableSprite.width,collectableSprite.height);
    vertex(x, y+heig, 0,collectableSprite.height);
    endShape();
  }
  void use(){
    active = false;
    collect.play();
    for(Collectable clb: collectables){
      if(clb.active)
        return;
    }
    locked = false;
    
  }
}
