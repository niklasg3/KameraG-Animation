/**
 * REALLY simple processing sketch for using webcam input
 * This sends 100 input values to port 6448 using message /wek/inputs
 **/

import processing.video.*;
import oscP5.*;
import netP5.*;
// laver en variable som jeg bruger til at lave en timer med. 
int timeout = 0;
// Definere video
Movie myMovie;
// Klasse som bruges til at definere hvilke klassifikation som bliver brugt vi Wekinator
int klasse = 0;
int numPixelsOrig;
int numPixels;
boolean first = true;

int boxWidth = 16;
int boxHeight = 12;
PImage photo;

int numHoriz = 640/boxWidth;
int numVert = 480/boxHeight;

color[] downPix = new color[numHoriz * numVert];


Capture video;

OscP5 oscP5;
NetAddress dest;

void setup() {
  // colorMode(HSB);
  // Sørger for at billedet fylder hele skærmen
  size(1920, 1080, P2D);
  //Her beder jeg den om at lytte til wekinator
  oscP5 = new OscP5(this, 12000);  
  // Definere Photo til at være et billede
  photo = loadImage("TestholmGaa.jpg");
  // Sørger for at loade billdet og sætte det i loop.
  myMovie = new Movie(this, "GaaVideo.mov");
  myMovie.loop();

  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    video = new Capture(this, 640, 480);
  } 
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    /* println("Available cameras:");
     for (int i = 0; i < cameras.length; i++) {
     println(cameras[i]);
     } */

    video = new Capture(this, 640, 480);

    // Start capturing the images from the camera
    video.start();

    numPixelsOrig = video.width * video.height;
    loadPixels();
    noStroke();
  }

  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this, 9000);
  dest = new NetAddress("127.0.0.1", 6448);
}

void draw() {

  if (video.available() == true) {
    video.read();

    video.loadPixels(); // Make the pixels of video available
    /*for (int i = 0; i < numPixels; i++) {
     int x = i % video.width;
     int y = i / video.width;
     float xscl = (float) width / (float) video.width;
     float yscl = (float) height / (float) video.height;
     
     float gradient = diff(i, -1) + diff(i, +1) + diff(i, -video.width) + diff(i, video.width);
     fill(color(gradient, gradient, gradient));
     rect(x * xscl, y * yscl, xscl, yscl);
     } */
    int boxNum = 0;
    int tot = boxWidth*boxHeight;
    for (int x = 0; x < 640; x += boxWidth) {
      for (int y = 0; y < 480; y += boxHeight) {
        float red = 0, green = 0, blue = 0;

        for (int i = 0; i < boxWidth; i++) {
          for (int j = 0; j < boxHeight; j++) {
            int index = (x + i) + (y + j) * 640;
            red += red(video.pixels[index]);
            green += green(video.pixels[index]);
            blue += blue(video.pixels[index]);
          }
        }
        downPix[boxNum] = (int) green/tot;
        // downPix[boxNum] = color((float)red/tot, (float)green/tot, (float)blue/tot);
        fill(downPix[boxNum]);

        int index = x + 640*y;
        red += red(video.pixels[index]);
        green += green(video.pixels[index]);
        blue += blue(video.pixels[index]);
        // fill (color(red, green, blue));
        rect(x, y, boxWidth, boxHeight);
        boxNum++;
        /* if (first) {
         println(boxNum);
         } */
      }
    }
    
    if (frameCount % 2 == 0)
      sendOsc(downPix);
// Her sørger jeg får at hvis timeren er større end 0 begynder den at tælle nedad og at det så er klasse 1. Ellers hvis den er større eller det samme som 0 er det klasse 2. Når wekinator sætter Klasse værdien til at være 2, vil timeren starte på 120.
// efter noget tid når 120 er nået ned under 0, vil billedet skifte tilbage til klasse 1 (billede)
    if (timeout > 0) {
      klasse = 1;
      timeout = timeout - 1;
    } else if (timeout <= 0) {
      klasse = 2;      
    }
// Her tegner jeg video (klasse 1) og billede (klasse 2), men delikere billede og video ud til klasse. Tjekker om det er den rigtige klasse, og hvis det er så skal den vise det rigtige billede/video
    if (klasse == 1) {
      image(myMovie, 0, 0);
    } if (klasse == 2) {
      image(photo, 0, 0);
      photo.resize(width,height);
    }
    
    first = false;
    fill(0);
    text("Sending 100 inputs to port 6448 using message /wek/inputs", 10, 10);
  }
}
// Her tjekker jeg hvilke output det er og hvis det er output 1, sætter den det til klasse 1 og sætter timeout værdien til 120. Det er mere end 0 så den begynder at tælle ned, som jeg forklarede længere oppe
void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/output_1")) {
    klasse = 1;
    timeout = 120;
  }
  if (msg.checkAddrPattern("/output_2")) {
  
  }
}


float diff(int p, int off) {
  if (p + off < 0 || p + off >= numPixels)
    return 0;
  return red(video.pixels[p+off]) - red(video.pixels[p]) +
    green(video.pixels[p+off]) - green(video.pixels[p]) +
    blue(video.pixels[p+off]) - blue(video.pixels[p]);
}

void sendOsc(int[] px) {
  OscMessage msg = new OscMessage("/wek/inputs");
  // msg.add(px);
  for (int i = 0; i < px.length; i++) {
    msg.add(float(px[i]));
  }
  oscP5.send(msg, dest);
}
// caller et event for at få videon til at afspille hvert frame
void movieEvent(Movie m) {
  m.read();
}
