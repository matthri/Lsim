/// Fixture definition
class Fixture extends ScreenObject {
  int universe = 0;                                                             //< ArtNet Universe
  int address = 1;

  ArrayList<Pixel> pixelList = new ArrayList<Pixel>();

  int panAngle = 630;
  int tiltAngle = 270;
  Dynamics pan;
  Dynamics tilt;
  String panType = "Fork";                                                      // Fork,
  String tiltType = "Head";                                                     // Head, Cuboid
  PShape modelBase;
  PShape modelPan;
  PShape modelTilt;
  PVector sizePan = new PVector(100, 100, 100);
  PVector sizeTilt = new PVector(100, 100, 100);

  int chanPan = 1;                                                              // [1-512]
  int chanTilt = 2;


  Fixture() {
    super(new PVector(int(random(-100, 100)), int(random(-250, -50)), int(random(-100, 100))), new PVector(0, 0, 0));
    modelPan = loadShape("Headfork.obj");
    modelTilt = loadShape("Headcorpus.obj");
    modelPan.disableStyle();  // Ignore the colors in the SVG
    modelTilt.disableStyle();
    pan = new Dynamics();
    tilt = new Dynamics();
    pixelList.add(new Pixel());
  }

  void display() {
    checkMouseOver();
    fill(80);
    stroke(0);
    strokeWeight(1);

    pan.updateDest(int(dmxData[universe][constrain(address-1+chanPan-1, 0, 511)])*float(panAngle)/255.0);
    pan.move();
    tilt.updateDest(int(dmxData[universe][constrain(address-1+chanTilt-1, 0, 511)])*float(tiltAngle)/255.0 - float(tiltAngle)/2.0);
    tilt.move();

    for (Pixel p : pixelList) {
      p.updateChannels(address, dmxData[universe]);
    }


    PVector dummy = new PVector(0, 500, 0);
    dummy = rotateVector(dummy, -tilt.pos, 0, 0);
    dummy = rotateVector(dummy, 0, -pan.pos, 0);
    dummy = rotateVector(dummy, 0, 0, -rot.z);  // Sequence of rotations makes a difference!
    dummy = rotateVector(dummy, 0, -rot.y, 0);
    dummy = rotateVector(dummy, -rot.x, 0, 0);
    dummy.add(new PVector(pos3d.x, pos3d.y, pos3d.z));

    /*
    stroke(dimmer);
     strokeWeight(5);
     line(pos3d.x, pos3d.y, pos3d.z, dummy.x, dummy.y, dummy.z);
     */

    pushMatrix();
    translate(pos3d.x, pos3d.y, pos3d.z);
    rotateX(radians(rot.x));
    rotateY(radians(rot.y));
    rotateZ(radians(rot.z));
    rotateY(radians(pan.pos));
    fill(clr);
    stroke(0);
    strokeWeight(2);
    if (panType.equals("Fork")) {
      modelPan.resetMatrix();      // ToDo keep an eye on this, it's run every frame and might slow things down (?)
      modelPan.scale(sizePan.x/100.0, sizePan.y/100.0, sizePan.z/100.0);
      shape(modelPan);
    }
    rotateX(radians(tilt.pos));
    if (tiltType.equals("Head")) {
      modelTilt.resetMatrix();      // ToDo keep an eye on this, it's run every frame and might slow things down (?)
      modelTilt.scale(sizeTilt.x/100.0, sizeTilt.y/100.0, sizeTilt.z/100.0);
      shape(modelTilt);
    } else if (tiltType.equals("Cuboid")) {
      box(sizeTilt.x, sizeTilt.y, sizeTilt.z);      // ToDo: Implement scaling for obj models
    }
    for (Pixel p : pixelList) {
      p.display();
    }
    popMatrix();

    updatePos2d();
  }

  // ToDo move Dynamics GUI stuff to Dynamics class
  void loadGui() {
    Expandable headExp = new Expandable(new PVector(0, 0), new PVector(0, 0), true, true);
    headExp.put(new SpinBox(new PVector(10, 0), new PVector(80, 25), this, "pos3d.x", "pos3d.x", pos3d.x, 1.0));
    headExp.put(new SpinBox(new PVector(10, 0), new PVector(80, 25), this, "pos3d.y", "pos3d.y", pos3d.y, 1.0));
    headExp.put(new SpinBox(new PVector(10, 0), new PVector(80, 25), this, "pos3d.z", "pos3d.z", pos3d.z, 1.0));
    headExp.put(new SpinBox(new PVector(10, 0), new PVector(80, 25), this, "rot.x", "rot.x", rot.x, 1.0));
    headExp.put(new SpinBox(new PVector(10, 0), new PVector(80, 25), this, "rot.y", "rot.y", rot.y, 1.0));
    headExp.put(new SpinBox(new PVector(10, 0), new PVector(80, 25), this, "rot.z", "rot.z", rot.z, 1.0));
    headExp.put(new IntBox(new PVector(10, 0), new PVector(80, 25), this, "Universe", "Universe", universe, 1, 0, QTY_UNIVERSES-1));
    headExp.put(new IntBox(new PVector(10, 0), new PVector(80, 25), this, "Address", "Address", address, 1, 1, 512));
    headExp.put(new IntBox(new PVector(10, 0), new PVector(100, 25), this, "Pan Angle", "Pan Angle", panAngle, 1, 90, 720));
    headExp.put(new SpinBox(new PVector(20, 0), new PVector(80, 25), this, "Pan Accel", "Pan Accel", pan.maxAcc, 0.01));
    headExp.put(new SpinBox(new PVector(20, 0), new PVector(80, 25), this, "Pan Speed", "Pan Speed", pan.maxSpd, 0.01));
    headExp.put(new SpinBox(new PVector(20, 0), new PVector(80, 25), this, "Pan Tweak", "Pan Tweak", pan.maxSpdTweak, 0.01));
    headExp.put(new IntBox(new PVector(10, 0), new PVector(100, 25), this, "Tilt Angle", "Tilt Angle", tiltAngle, 1, 90, 360));
    headExp.put(new SpinBox(new PVector(20, 0), new PVector(80, 25), this, "Tilt Accel", "Tilt Accel", tilt.maxAcc, 0.01));
    headExp.put(new SpinBox(new PVector(20, 0), new PVector(80, 25), this, "Tilt Speed", "Tilt Speed", tilt.maxSpd, 0.01));
    headExp.put(new SpinBox(new PVector(20, 0), new PVector(80, 25), this, "Tilt Tweak", "Tilt Tweak", tilt.maxSpdTweak, 0.01));
    headExp.put(new IntBox(new PVector(10, 0), new PVector(60, 25), this, "Channel Pan", "Channel Pan", chanPan, 1, 1, 512));
    headExp.put(new IntBox(new PVector(10, 0), new PVector(60, 25), this, "Channel Tilt", "Channel Tilt", chanTilt, 1, 1, 512));
    Expandable selectPanExp = new Expandable(new PVector(10, 0), new PVector(0, 0), true, false);
    selectPanExp.put(new Button(new PVector(0, 0), new PVector(120, 30), this, "Fork Model", "Fork Model"));    // ToDo add representation in Button class
    selectPanExp.put(new IntBox(new PVector(0, 0), new PVector(80, 25), this, "Pan Size LR", "Pan Size LR", int(sizePan.x), 1, 1, 10000));
    selectPanExp.put(new IntBox(new PVector(0, 0), new PVector(80, 25), this, "Pan Size UD", "Pan Size UD", int(sizePan.y), 1, 1, 10000));
    selectPanExp.put(new IntBox(new PVector(0, 0), new PVector(80, 25), this, "Pan Size FB", "Pan Size FB", int(sizePan.z), 1, 1, 10000));
    headExp.put(selectPanExp);
    Expandable selectTiltExp = new Expandable(new PVector(10, 0), new PVector(0, 0), true, false);
    selectTiltExp.put(new Button(new PVector(0, 0), new PVector(120, 30), this, "Head Model", "Head Model"));
    selectTiltExp.put(new Button(new PVector(0, 0), new PVector(120, 30), this, "Cuboid Model", "Cuboid Model"));
    selectTiltExp.put(new IntBox(new PVector(0, 0), new PVector(80, 25), this, "Tilt Size LR", "Tilt Size LR", int(sizeTilt.x), 1, 1, 10000));
    selectTiltExp.put(new IntBox(new PVector(0, 0), new PVector(80, 25), this, "Tilt Size FB", "Tilt Size FB", int(sizeTilt.y), 1, 1, 10000));
    selectTiltExp.put(new IntBox(new PVector(0, 0), new PVector(80, 25), this, "Tilt Size UD", "Tilt Size UD", int(sizeTilt.z), 1, 1, 10000));
    headExp.put(selectTiltExp);
    menuExpRight.put(headExp);
    for (Pixel p : pixelList) {
      p.loadGui();
    }
  }

  String getSaveString() {
    /*
    XML tempXml = parseXML("<Fixture><Mechanical></Mechanical></Fixture>");
     XML nodeFixture = tempXml.getChild("Mechanical");
     XML x = nodeFixture.addChild("Property");
     x.setString("name", "panAngle");
     x.setString("value", str(panAngle));
     saveXML(tempXml, "xml/" + name + ".xml");
     */
    String saveStr = "";
    saveStr +=
      super.getSaveString() + ";" +
      str(universe) + ";" +
      str(address) + ";" +
      str(panAngle) + ";" +
      str(tiltAngle) + ";" +
      panType + ";" +
      tiltType + ";" +
      str(sizePan.x) + ";" +
      str(sizePan.y) + ";" +
      str(sizePan.z) + ";" +
      str(sizeTilt.x) + ";" +
      str(sizeTilt.y) + ";" +
      str(sizeTilt.z) + ";" +
      pan.getSaveString() + ";" +
      tilt.getSaveString() + ";" +
      str(pixelList.size());
    for (Pixel p : pixelList) {
      saveStr += ";" + p.getSaveString();
    }
    return(saveStr);
  }

  void setLoadArray(String[] iProps) {
    try {
      super.setLoadArray(Arrays.copyOfRange(iProps, 0, 7));
      universe = int(iProps[7]);
      address = int(iProps[8]);
      panAngle = int(iProps[9]);
      tiltAngle = int(iProps[10]);
      panType = iProps[11];
      tiltType = iProps[12];
      sizePan = new PVector(float(iProps[13]), float(iProps[14]), float(iProps[15]));
      sizeTilt = new PVector(float(iProps[16]), float(iProps[17]), float(iProps[18]));
      pan.setLoadArray(Arrays.copyOfRange(iProps, 19, 22));
      tilt.setLoadArray(Arrays.copyOfRange(iProps, 22, 25));
      int numOfPixels = int(iProps[25]);
      pixelList.clear();
      for (int n=0; n<numOfPixels; n++) {
        Pixel tempPixel = new Pixel();
        tempPixel.setLoadArray(Arrays.copyOfRange(iProps, 26+n*14, 40+n*14));
        pixelList.add(tempPixel);
      }
      println("Loaded Fixture " + name);
    } 
    catch(Exception e) {
      println(e);
    }
  }


  /*
    void calcPanTilt() {
   PVector tempVec = new PVector(0, 0, 0);
   tempVec = PVector.sub(headPointAt, pos);   // headPointAt = Point in 3D space to point the head at
   tempVec = rotateVector(tempVec, rotX, 0, 0);  // Sequence of rotations makes a difference!
   tempVec = rotateVector(tempVec, 0, rotY, 0);
   tempVec = rotateVector(tempVec, 0, 0, rotZ);
   
   pan = degrees(atan2(tempVec.x, tempVec.z));
   tilt = degrees(acos(tempVec.y/tempVec.mag()));
   
   
   // For Art-Net Output
   int actualPanRange  = 256*360/panRange;       // <8 bit> * <Pan Range of Sphere Coords> / <Fixture Pan Range>
   int actualTiltRange = 127*180/(tiltRange/2);  // <8 bit> * <Tilt Range of Sphere Coords> / <Fixture Tilt Range>
   byte  panByte = byte(constrain(map(pan, -180, 180, 127-(actualPanRange/2), 127+(actualPanRange/2)), 0, 255));    //ToDo: panRange/TiltRange berücksichtigen
   byte tiltByte = byte(constrain(map(tilt,   0, 180, 127, 127+actualTiltRange), 0, 255));
   setDMXchannel(109, (panInvert ? (255-panByte) : panByte));
   setDMXchannel(111, (tiltInvert ? (255-tiltByte) : tiltByte));
   myBus.sendControllerChange(15, 1, int( panByte*127/255));
   myBus.sendControllerChange(15, 2, int(tiltByte*127/255));
   //println(pan, tilt, panByte, tiltByte);
   }*/
}
