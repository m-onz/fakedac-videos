
import com.hamoid.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.spi.*;

VideoExport videoExport;

String audioFilePath = "tygerblue_180Circ_excerpt.wav";

String SEP = "|";
float movieFPS = 30;
float frameDuration = 1 / movieFPS;
BufferedReader reader;

ArrayList<Rectangle> rectangles;

float searchRadius = 0;
float radiusIncr = 1;
float tryPerIncr = 500;
int minRectSize = 10;
int maxRectSize = 100;

int bands = 128;
float smoothingFactor = 0.25;
float sum;
float[] sum2 = new float[bands];
int scale = 5;
float barWidth;

int samples2 = 100;

int incro = 0;

void setup() {
  fullScreen(P3D);
  rectangles = new ArrayList<Rectangle>();
  colorMode(HSB);
  frameRate(1000);
  audioToTextFile(audioFilePath);
  reader = createReader(audioFilePath + ".txt");
  videoExport = new VideoExport(this);
  videoExport.setFrameRate(movieFPS);
  videoExport.setAudioFileName(audioFilePath);
  videoExport.setQuality(100, 256);
  videoExport.startMovie();
}



void draw() {
  
  //
  String line;
  try {
    line = reader.readLine();
  }
  catch (IOException e) {
    e.printStackTrace();
    line = null;
  }
  if (line == null) {
    videoExport.endMovie();
    exit();
  } else {
    String[] p = split(line, SEP);
    float soundTime = float(p[0]);
    int average = 0;
    while (videoExport.getCurrentTime() < soundTime + frameDuration * 0.5) {

      for (int i = 0; i < p.length; i++) {
        average += float(p[i]);
      }      
      incro += ((float) average / 61) / 5;
      lights();
      background(11);
      
      fill(0);
      
      pushMatrix();
      scale(noise(incro / 2000) * 2);

      for (int i = 0; i < tryPerIncr; i++) {
        float rAngle = random(TWO_PI);
        float rSize = random(minRectSize, maxRectSize);
        Rectangle r = new Rectangle(cos(rAngle) * searchRadius, sin(rAngle) * searchRadius, rSize);
        boolean placeable = true;
        for (Rectangle other : rectangles) {
          if (r.intersect(other)) {
            placeable = false;
            break;
          }
        }
        if (placeable) rectangles.add(r);
      }

      translate(width / 2, height / 2);
      
      if (float(p[11]) > 1) {
        fill(255);
        sphere(050); 
      }      
      rotateY(noise(incro*PI / 9000) * 100 - 50);
      rotateX(noise(incro*PI / 10000) * 100 - 50);
      rotateZ(noise(incro*PI / 11000) * 100 - 50);
          
      for (Rectangle r : rectangles) {
        r.display(incro);
      }
 
      stroke(255);
      noFill();
      circle(0, 0, searchRadius * 2);

      searchRadius += radiusIncr;
 
      if (searchRadius >= width / 2) {
        tryPerIncr = 0;
      }
      
      popMatrix();

      videoExport.saveFrame();
    }
  }
  
  
}

class Rectangle {
  float x, y, size;

  Rectangle(float x, float y, float size) {
    this.x = x;
    this.y = y;
    this.size = size;
  }

  void display(int framecount) {
    pushMatrix();
    rectMode(CENTER);
    noStroke();

    fill(noise(framecount*PI/900-this.size)*255, 255, 255);
    translate(x, y, noise(framecount*PI/300-this.size)*(framecount % 2000)-525);
    
    rotateX(noise(framecount*PI/900-this.size)*11);
    rotateY(noise(framecount*PI/900-this.size)*11);
    rotateZ(noise(framecount*PI/900-this.size)*11);
    
    box(size, 70, size);
    popMatrix();
  }

  boolean intersect(Rectangle other) {
    return (other.x - other.size / 2 < x + size / 2) &&
      (other.x + other.size / 2 > x - size / 2) &&
      (other.y - other.size / 2 < y + size / 2) &&
      (other.y + other.size / 2 > y - size / 2);
  }
}

void audioToTextFile(String fileName) {
  PrintWriter output;
  Minim minim = new Minim(this);
  output = createWriter(dataPath(fileName + ".txt"));
  AudioSample track = minim.loadSample(fileName, 2048);
  int fftSize = 1024;
  float sampleRate = track.sampleRate();
  float[] fftSamplesL = new float[fftSize];
  float[] fftSamplesR = new float[fftSize];
  float[] samplesL = track.getChannel(AudioSample.LEFT);
  float[] samplesR = track.getChannel(AudioSample.RIGHT);  
  FFT fftL = new FFT(fftSize, sampleRate);
  FFT fftR = new FFT(fftSize, sampleRate);
  fftL.logAverages(22, 3);
  fftR.logAverages(22, 3);
  int totalChunks = (samplesL.length / fftSize) + 1;
  int fftSlices = fftL.avgSize();
  for (int ci = 0; ci < totalChunks; ++ci) {
    int chunkStartIndex = ci * fftSize;   
    int chunkSize = min( samplesL.length - chunkStartIndex, fftSize );
    System.arraycopy( samplesL, chunkStartIndex, fftSamplesL, 0, chunkSize);      
    System.arraycopy( samplesR, chunkStartIndex, fftSamplesR, 0, chunkSize);      
    if ( chunkSize < fftSize ) {
      java.util.Arrays.fill( fftSamplesL, chunkSize, fftSamplesL.length - 1, 0.0 );
      java.util.Arrays.fill( fftSamplesR, chunkSize, fftSamplesR.length - 1, 0.0 );
    }
    fftL.forward( fftSamplesL );
    fftR.forward( fftSamplesL );
    StringBuilder msg = new StringBuilder(nf(chunkStartIndex/sampleRate, 0, 3).replace(',', '.'));
    for (int i=0; i<fftSlices; ++i) {
      msg.append(SEP + nf(fftL.getAvg(i), 0, 4).replace(',', '.'));
      msg.append(SEP + nf(fftR.getAvg(i), 0, 4).replace(',', '.'));
    }
    output.println(msg.toString());
  }
  track.close();
  output.flush();
  output.close();
  println("Sound analysis done: based on video export withAudioViz example.");
}
