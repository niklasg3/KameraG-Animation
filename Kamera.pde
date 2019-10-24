/**
* REALLY simple processing sketch for using webcam input
* This sends 100 input values to port 6448 using message /wek/inputs
**/
import processing.sound.*;
import processing.video.*;
import oscP5.*;
import netP5.*;
// Her har jeg lavet en float som skal bruges til at wekinator, til at få et output på de forskellige lyde
 float nutone = 440;
 // her har jeg lavet de konstanter som skal bruges til at sætte lyden i den rigtige frekvens
final float TONE_C = 659.25;
final float TONE_g = 783.99;
final float TONE_c = 1046.50;
final float TONE_d = 1174.66;
final float TONE_e = 1318.51;

int lyd;

SinOsc sine;

int numPixelsOrig;
int numPixels;
boolean first = true;

int boxWidth = 64;
int boxHeight = 48;

int numHoriz = 640/boxWidth;
int numVert = 480/boxHeight;
 
color[] downPix = new color[numHoriz * numVert];


Capture video;

OscP5 oscP5;
NetAddress dest;

void setup() {
 // colorMode(HSB);
  size(640, 480, P2D);
  // her sørger jeg for at min kamera lytter til wekinator på port 12000
  oscP5 = new OscP5(this,12000);  
 

  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    video = new Capture(this, 640, 480);
  } if (cameras.length == 0) {
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
  oscP5 = new OscP5(this,9000);
  dest = new NetAddress("127.0.0.1",6448);
  // sørger for at der bliver afspillet en lyd
  sine = new SinOsc(this);
  sine.play();
  
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
       downPix[boxNum] =  color(red/tot, green/tot, blue/tot);
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
  
 
  if(frameCount % 2 == 0)
    sendOsc(downPix);
 // sine.pan(map(mouseX,  0, width,  -1.0,  1.0));
  }
  first = false;
  fill(0);
  text("Sending 100 inputs to port 6448 using message /wek/inputs", 10, 10);
  // Denne linje sørger for at skifte tonen fra 440Hz til den ønskede tone i de
  // 5 forskellige klassefikikationer  
  if (lyd ==1) nutone = TONE_C;
  if (lyd ==2) nutone = TONE_g;
  if (lyd ==3) nutone = TONE_c;
  if (lyd ==4) nutone = TONE_d;
  if (lyd ==5) nutone = TONE_e;
  
  sine.freq(nutone);
  

}
// Her kalder jeg et event mellem wekinator og kamera. Wekinator bestemmer floatvalue af min "cut)
  void oscEvent(OscMessage message){
    if (message.checkAddrPattern("/wek/outputs")){
    lyd = (int)message.get(0).floatValue();
    }
    
    
  }



float diff(int p, int off) {
  if(p + off < 0 || p + off >= numPixels)
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
