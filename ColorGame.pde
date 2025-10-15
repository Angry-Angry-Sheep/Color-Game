import gifAnimation.*;
import processing.sound.*;

Gif introGif;

boolean inIntro = true;
boolean inGame = false;
boolean gameOver = false;

String[] colorNames = {"RED", "GREEN", "BLUE", "YELLOW", "CYAN", "MAGENTA"};
color[] colors = {#FF0000, #00FF00, #0000FF, #FFFF00, #00FFFF, #FF00FF};

String currentWord;
color currentColor;
boolean isMatch;

int score = 0;
PFont font;
PFont smallFont;

int prevColorIndex = -1;
int prevWordIndex = -1;
SoundFile successSound;
SoundFile failSound;

boolean hoverStart = false;

float glowPulse = 0;

float timeLeft = 100;        
float maxTime = 100;         
float timeDecay = 0.5;       
boolean hasClickedThisRound; 

float averageScore = 10;  
float restartDelay = 0.8; 
float endScreenStartTime = 0;
SoundFile introMusic;

int highScore = 0;

// ===================== SETUP =====================
void setup() {
  size(800, 600);
  rectMode(CORNER);
  font = createFont("Arial", 32);
  smallFont = createFont("Arial", 16); // used for graph labels
  textFont(font);
  smooth(8);

  introGif = new Gif(this, "gif.gif");
  introGif.loop();

successSound = new SoundFile(this, "success.mp3");
failSound = new SoundFile(this, "fail.mp3");
introMusic = new SoundFile(this, "MUSIC.mp3");
introMusic.loop();
}

// ===================== MAIN DRAW LOOP =====================
void draw() {
  background(0);
  glowPulse = (sin(millis() * 0.003) + 1) * 0.5;

  if (inIntro) {
    drawIntro();
  } 
  else if (inGame) {
    drawGame();
    updateTimer();
  } 
  else if (gameOver) {
    drawGameOver();
  }
}

// ===================== INTRO SCREEN =====================
void drawIntro() {
  textFont(font);
  image(introGif, 0, 0, width, height);

  fill(255);
  textAlign(CENTER);
  textSize(56);
  text("Color Match Game", width/2, height/2 - 100);

  // Start button
  float btnX = width/2 - 100;
  float btnY = height/2 + 70;
  float btnW = 200;
  float btnH = 60;

  hoverStart = overRect(btnX, btnY, btnW, btnH);

  pushMatrix();
  translate(width/2, height/2 + 100);
  float scaleAmt = hoverStart ? 1.05 : 1.0;
  scale(scaleAmt);

  // Button shadow
  noStroke();
  fill(0, 0, 0, 80);
  rectMode(CENTER);
  rect(4, 6, 200, 60, 15);

  // Button color states
  if (hoverStart && mousePressed) fill(0, 140, 230);
  else if (hoverStart) fill(0, 180, 255);
  else fill(0, 150, 230);
  rect(0, 0, 200, 60, 15);

  // Button label
  fill(255);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("START", 0, 0);
  popMatrix();
}

// ===================== TIMER SYSTEM =====================
void updateTimer() {
  if (!hasClickedThisRound) timeLeft -= timeDecay;

  float barWidth = map(timeLeft, 0, maxTime, 0, width - 40);
  float barHeight = 25;
  float x = 20;
  float y = 20;

  noStroke();
  fill(100, 100, 100, 150);
  rect(x, y, width - 40, barHeight, 10);

  // color change on bar
  color barColor = lerpColor(color(255, 60, 60), color(60, 255, 60), timeLeft / maxTime);
  fill(barColor);
  rect(x, y, barWidth, barHeight, 10);

  if (timeLeft <= 0) {
    inGame = false;
    gameOver = true;
    endScreenStartTime = millis() / 1000.0;
  }
}

// ===================== MOUSE HANDLING =====================
void mousePressed() {
  if (inIntro && hoverStart) {
    // Stop intro music and start game
    if (introMusic.isPlaying()) introMusic.stop();
    
    inIntro = false;
    inGame = true;
    score = 0;
    nextRound();
  } 
  else if (inGame) {
    // Decide if clicked correct side
    boolean clickedMatch = (mouseX < width / 2);
    boolean correct = (clickedMatch && isMatch) || (!clickedMatch && !isMatch);
    hasClickedThisRound = true;

    if (correct) {
      successSound.play();
      score++;
      nextRound();
    } else {
      failSound.play();
      inGame = false;
      gameOver = true;
      endScreenStartTime = millis() / 1000.0;
      if (score > highScore) highScore = score;
    }
  } 
  else if (gameOver) {
    // Restart logic
    float now = millis() / 1000.0;
    if (now - endScreenStartTime > restartDelay + 0.25) {
      inIntro = true;
      gameOver = false;
      // Restart intro music
      if (!introMusic.isPlaying()) introMusic.loop();
    }
  }
}


// ===================== GAME SCREEN =====================
void drawGame() {
  textFont(font);
  noStroke();
  rectMode(CORNER);

  // Two halves for Match / Not Match
  fill(180, 255, 180);
  rect(0, 0, width / 2, height);

  fill(255, 180, 180);
  rect(width / 2, 0, width / 2, height);

  stroke(255);
  strokeWeight(5);
  line(width / 2, 0, width / 2, height);
  noStroke();

  // display the score
  fill(0);
  textAlign(LEFT, TOP);
  textSize(28);
  text("Score: " + score, 20, 60);

  // display the colored word
  textAlign(CENTER, CENTER);
  textSize(110);
  fill(currentColor);
  text(currentWord, width / 2, height / 2);

  // lable section of each side
  textSize(52);
  textAlign(CENTER);
  float outlineThickness = 4;
  float yPos = height - 55;

  drawOutlinedText("MATCH", width / 4, yPos, color(255), color(0, 160, 0), outlineThickness);
  drawOutlinedText("NOT MATCH", 3 * width / 4, yPos, color(255), color(200, 0, 0), outlineThickness);
}

// ===================== OUTLINED TEXT =====================
void drawOutlinedText(String txt, float x, float y, color outline, color fillCol, float thickness) {
  textFont(font);
  textAlign(CENTER, CENTER);
  fill(outline);
  for (float a = 0; a < TWO_PI; a += PI/8) {
    float dx = cos(a) * thickness;
    float dy = sin(a) * thickness;
    text(txt, x + dx, y + dy);
  }
  fill(fillCol);
  text(txt, x, y);
}

// ===================== NEW ROUND =====================
void nextRound() {
  int n = colorNames.length;

  isMatch = random(1) < 0.5;
  int colorIndex = int(random(n));
  int wordIndex;

  if (isMatch) wordIndex = colorIndex;
  else {
    wordIndex = int(random(n));
    while (wordIndex == colorIndex) wordIndex = int(random(n));
  }

  // prevent repeating the same combo twice
  if (colorIndex == prevColorIndex || wordIndex == prevWordIndex) {
    nextRound();
    return;
  }

  currentColor = colors[colorIndex];
  currentWord = colorNames[wordIndex];
  prevColorIndex = colorIndex;
  prevWordIndex = wordIndex;

  // reset timer
  timeLeft = maxTime;
  hasClickedThisRound = false;

  // Timer drains a faster
  timeDecay = 0.4 + 1.0 * (1 - exp(-score / 18.0));
}

// ===================== GAME OVER SCREEN =====================
void drawGameOver() {
  textFont(font);
  background(20);
  textAlign(CENTER);
  fill(255);
  textSize(60);
  text("Game Over!", width / 2, 80);

  textSize(36);
  text("Score: " + score, width / 2, 140);
  
  fill(200, 255, 200);
  textSize(28);
  text("High Score: " + highScore, width / 2, 170);


  // iq calculation
  float iq = 40 + 60 * (1 - exp(-(score / averageScore) * 1.2));
  iq = constrain(iq, 40, 160);

  textSize(28);
  text("Your IQ: " + nf(iq, 0, 1), width / 2, 200);

  drawIQBellCurve(iq);

  // add delayed fade-in "Click to restart" message
  float elapsed = (millis() / 1000.0) - endScreenStartTime;
  if (elapsed > restartDelay) {
    textSize(24);
    fill(255, map(elapsed, restartDelay, restartDelay + 0.5, 0, 255));
    text("Click to restart...", width / 2, height - 40);
  }
}

// ===================== IQ GRAPH =====================
void drawIQBellCurve(float iq) {
  pushMatrix();
  translate(100, height - 180);
  float graphW = width - 200;
  float graphH = 150;

  // Base line
  stroke(255);
  line(0, graphH, graphW, graphH);

  // Bell curve
  noFill();
  stroke(200);
  beginShape();
  for (float x = 0; x <= graphW; x += 2) {
    float iqVal = map(x, 0, graphW, 40, 160);
    float y = bellCurveY(iqVal, 100, 15);
    vertex(x, graphH - y * graphH * 0.9);
  }
  endShape();

  // Axis label for iq
  fill(255);
  textAlign(CENTER, TOP);
  textFont(smallFont);
  for (int label = 40; label <= 160; label += 20) {
    float x = map(label, 40, 160, 0, graphW);
    text(label, x, graphH + 8);
  }
  text("IQ", graphW / 2, graphH + 30);

  // Red marker for player IQ
  float playerX = map(iq, 40, 160, 0, graphW);
  float playerY = bellCurveY(iq, 100, 15);
  playerY = graphH - playerY * graphH * 0.9;

  fill(255, 0, 0);
  noStroke();
  ellipse(playerX, playerY, 12, 12);

  stroke(255, 0, 0);
  line(playerX, playerY - 20, playerX, playerY - 60);
  fill(255, 0, 0);
  noStroke();
  textAlign(CENTER);
  text("You are here", playerX, playerY - 75);
  popMatrix();
}

// bell curve iq graph y pos
float bellCurveY(float x, float mean, float stdDev) {
  float exponent = -sq(x - mean) / (2 * sq(stdDev));
  return (1 / (stdDev * sqrt(TWO_PI))) * exp(exponent) * 100;
}

// ===================== BASIC UTILITY =====================
boolean overRect(float x, float y, float w, float h) {
  return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
}
