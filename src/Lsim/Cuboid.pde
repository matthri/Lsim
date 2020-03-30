class Cuboid extends ScreenObject {
  PVector size3d;

  Cuboid() {
    super(new PVector(int(random(-100, 100)), int(random(-250, -50)), int(random(-100, 100))), new PVector(0, 0, 0));
    size3d = new PVector(40, 40, 40);
  }

  void display() {
    checkMouseOver();

    PVector dummy = new PVector(0, 500, 0);
    dummy = rotateVector(dummy, 0, 0, -rot.z);  // Sequence of rotations makes a difference!
    dummy = rotateVector(dummy, 0, -rot.y, 0);
    dummy = rotateVector(dummy, -rot.x, 0, 0);
    dummy.add(new PVector(pos3d.x, pos3d.y, pos3d.z));

    pushMatrix();
    translate(pos3d.x, pos3d.y, pos3d.z);
    rotateX(radians(rot.x));
    rotateY(radians(rot.y));
    rotateZ(radians(rot.z));
    stroke(0);
    strokeWeight(1);
    fill(clr);
    box(size3d.x, size3d.y, size3d.z);
    popMatrix();

    updatePos2d();

    fill(255);
    textSize(height/80);
    textAlign(CENTER, CENTER);
    text(name, pos3d.x, pos3d.y-15-size3d.y/2, pos3d.z);
  }

  // Draw Center Of Mass symbol; Has to be called in main after resetting camera() for correct 2D display
  void drawCom() {
    image(comImg, pos2d.x-7, pos2d.y-7, 14, 14);
  }

  void loadGui() {
    Expandable tempCubExp = new Expandable(new PVector(0, 0), new PVector(0, 0), "Cuboid", true, true, CLR_MENU_LV1);
    tempCubExp.put(new NameBox(new PVector(0, 0), new PVector(120, 25), this, "name", "Name", name));
    tempCubExp.put(new SpinBox(new PVector(0, 0), new PVector(80, 25), this, "pos3d.x", "pos3d.x", pos3d.x, 1.0));
    tempCubExp.put(new SpinBox(new PVector(0, 0), new PVector(80, 25), this, "pos3d.y", "pos3d.y", pos3d.y, 1.0));
    tempCubExp.put(new SpinBox(new PVector(0, 0), new PVector(80, 25), this, "pos3d.z", "pos3d.z", pos3d.z, 1.0));
    tempCubExp.put(new SpinBox(new PVector(0, 0), new PVector(80, 25), this, "rot.x", "rot.x", rot.x, 1.0));
    tempCubExp.put(new SpinBox(new PVector(0, 0), new PVector(80, 25), this, "rot.y", "rot.y", rot.y, 1.0));
    tempCubExp.put(new SpinBox(new PVector(0, 0), new PVector(80, 25), this, "rot.z", "rot.z", rot.z, 1.0));
    tempCubExp.put(new SpinBox(new PVector(0, 0), new PVector(80, 25), this, "size3d.x", "size3d.x", size3d.x, 1.0));
    tempCubExp.put(new SpinBox(new PVector(0, 0), new PVector(80, 25), this, "size3d.y", "size3d.y", size3d.y, 1.0));
    tempCubExp.put(new SpinBox(new PVector(0, 0), new PVector(80, 25), this, "size3d.z", "size3d.z", size3d.z, 1.0));
    tempCubExp.put(new Button(new PVector(0, 0), new PVector(60, 30), this, "Copy Cuboid", "Copy", CLR_MENU_LV1));
    tempCubExp.put(new Button(new PVector(60+SIZE_GUTTER, 0-30-SIZE_GUTTER), new PVector(60, 30), this, "Delete Cuboid", "Delete", CLR_MENU_LV1));
    menuExpRight.put(tempCubExp);
  }

  String getSaveString() {
    return(
      super.getSaveString() + ";" +
      str(size3d.x) + ";" +
      str(size3d.y) + ";" +
      str(size3d.z)
      );
  }

  void setLoadArray(String[] iProps) {
    try {
      super.setLoadArray(Arrays.copyOfRange(iProps, 0, 7));
      size3d = new PVector(float(iProps[7]), float(iProps[8]), float(iProps[9]));
      println("Loaded Cuboid " + name);
    }
    catch(Exception e) {
      println(e);
    }
  }
}
