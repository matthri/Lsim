class GuiObject {
  PVector pos;    // Modified automatically in draw() to align objects
  PVector size;
  String valStr = "42.0";
  String propName = "";
  float stepSize = 1.0;
  color clr = color(255, 0, 255);

  GuiObject(PVector iPos, PVector iSize, String iPropName, float iInitialVal, float iStepSize) {
    pos = iPos;
    size = iSize;
    propName = iPropName;
    valStr = str(iInitialVal);
    stepSize = iStepSize;
  }

  void editValMouse(float iEventGetCount) {
    iEventGetCount *= stepSize;
    if (keyPressed  &&  key==CODED  &&  keyCode==CONTROL) {
      iEventGetCount *= 10;
    } else if (keyPressed  &&  key==CODED  &&  keyCode==SHIFT) {
      iEventGetCount *= 100;
    }
    valStr = str(float(valStr)-iEventGetCount);
  }

  void editValKey() {
  }

  void display() {
  }

  boolean checkMouseOver() {
    if (mouseX > pos.x  &&  mouseX < (pos.x+size.x)  &&  mouseY > pos.y  &&  mouseY < (pos.y+size.y)) {
      if (flag  &&  mousePressed) {
        flag = false;
        selectedGuiObject = guiList.indexOf(this);
        return(true);
      }
    }
    return(false);
  }
}
