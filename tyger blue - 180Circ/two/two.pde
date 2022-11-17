
import com.hamoid.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.spi.*;

BeatDetect beat;

VideoExport videoExport;

String audioFilePath = "tygerblue_180Circ_excerpt.wav";

String SEP = "|";
float movieFPS = 30;
float frameDuration = 1 / movieFPS;
BufferedReader reader;

ArrayList<Circle> circles;

void setup() {
  fullScreen(P3D);
  frameRate(1000);
  beat = new BeatDetect();
  audioToTextFile(audioFilePath);
  reader = createReader(audioFilePath + ".txt");
  videoExport = new VideoExport(this);
  videoExport.setFrameRate(movieFPS);
  videoExport.setAudioFileName(audioFilePath);
  videoExport.setQuality(100, 256);
  videoExport.startMovie();
  strokeWeight(2);
  colorMode(HSB);
  
  sphereDetail(8);
  
  circles = new ArrayList<Circle>();
}

void draw() {
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

    while (videoExport.getCurrentTime() < soundTime + frameDuration * 0.5) {
      background(noise(frameCount*PI/9000)*50);

      pushMatrix();
      
      for (int i = 1; i < p.length/2; i++) {
        if (circles.size() < 111) circles.add(new Circle(float(p[i]) * 100));
        pushMatrix();
        translate(width / 2, height / 2);
        sphereDetail(20);
        stroke(0);
        noFill();
        sphere(float(p[i])*5);
        popMatrix();
      }
      
      for (int i = circles.size()-1; i >= 0; i--) { 
        Circle c = circles.get(i);
        c.display();
        if (c.finished()) {
          circles.remove(i);
        }
      }
      popMatrix();
      videoExport.saveFrame();
    }
    
  }
  
  //if (mousePressed) {
  //  saveFrame("screenshot-######.png");
  //}
  
}

class Circle {
  float size;
  float life;
  float seed;
  int detail;
  
  Circle(float _size) {
    size = _size;
    life = _size;
    seed = random (1);
    detail = (int) random(9);
  }

  boolean finished() {
    if (life <= 0) {
      return true;
    } else {
      return false;
    }
  }
  void display() {
    life -= 4;
    sphereDetail(detail);
    pushMatrix();
    stroke(life % 255);
    translate(width / 2, height / 2);
    rotateX(seed);
    rotateY(seed);
    rotateZ(seed);
    sphere(life);
    popMatrix();
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
      msg.append(SEP + nf(fftL.getAvg(i), 0, 4).replace(',', '.') + SEP + "xx" );
      msg.append(SEP + nf(fftR.getAvg(i), 0, 4).replace(',', '.') + SEP + "xx" );
    }
    output.println(msg.toString());
  }
  
  track.close();
  output.flush();
  output.close();
  println("Sound analysis done: based on video export withAudioViz example.");
}
