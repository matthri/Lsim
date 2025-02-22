import hypermedia.net.*;    // For UDP
import java.util.Arrays;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
UDP udp;


final int OPACITY_BEAMS = 180;       // [0-255]
final int LENGTH_BEAMS = 2000;
final int RESOLUTION_BEAMS = 10;
final float POS_TOLERANCE = 0.2;    // Threshold for moving lights pan and tilt
final int QTY_UNIVERSES = 4;
final int SIZE_GUTTER = 5;
int SIZE_MENU_RIGHT;
int SIZE_MENU_LEFT;
String PATH_FIXTURES = "/save/fixtures/";
String PATH_ENVIRONMENTS = "/data/";                                            // .obj files must be in data/ dir in Processing
String PATH_PROJECTS = "/save/projects/";
String PATH_BACKUPS = "/save/autobackups/";
// Saturation 57%, Brightness 100%, Hue varied
final color CLR_MENU_LV1 = #FF00FF;
final color CLR_MENU_LV2 = #FFD68C;
final color CLR_MENU_LV3 = #6CE8FF;
final color CLR_NOTIF_SUCCESS = color(0, 255, 0);
final color CLR_NOTIF_INFO = color(50, 200, 255);
final color CLR_NOTIF_DANGER = color(255, 0, 0);
final int TTL_SUCCESS = 5;
final int TTL_INFO = 8;
final int TTL_DANGER = 20;

ArrayList<Fixture> fixtureList = new ArrayList<Fixture>();
ArrayList<Cuboid> cuboidList = new ArrayList<Cuboid>();
ArrayList<Notification> notificationsList = new ArrayList<Notification>();
Expandable menuExpLeft;
Expandable menuExpRight;
Button expandBtn;
float menuXpos = 0;                                                             // Closed -> 0, Expanded -> positive
byte menuState = 0;                                                             // 0=closed, 1=expanding, 2=expanded, 3=closing
boolean scrolling = false;
int menuScroll = 0;

String projectName = "Oops";

PVector camPos = new PVector(900, -300, 900);
PVector camLookAt = new PVector(0, -200, 0);
PImage comImg;
boolean showNamesAndComs = true;                                                // Toggle display of names and Center-Of-Mass icons

byte[] artnetHeader = {'A', 'r', 't', '-', 'N', 'e', 't', '\0'};
byte[][] dmxData = new byte[4][512];                                            // [universe][address]

ScreenObject selectedScreenObject = null;
GuiObject selectedGuiObject = null;
long lastFrameTime = 0;
long calcFrameRate = 60;
boolean lightsOff = false;                                                      // Activation of ambient/directional lights
boolean beamsOff = false;                                                       // Activation of beam cones
boolean flag = false;

Notification removeMyNotification;                                              // Buffer to avoid ConcurrentModificationException while deleting
ScreenObject reloadMyGui;     // GUI sometimes can't be reloaded directly because it would delete the calling element, instead, do it in main loop
boolean deleteMyGui = false;                                                    // Clear right hand side GUI (f.ex. when deleting a Fixture)

PShape environmentShape;
String environmentFileName = "";                                                // Save filename to be able to save environment later



/// @brief Run once upon application start to set everything up
void setup() {
  size(1500, 900, P3D);
  //fullScreen(P3D, 1);
  surface.setResizable(true);
  frameRate(60);

  SIZE_MENU_LEFT = width/9;
  SIZE_MENU_RIGHT = width/6;

  udp = new UDP(this, 6454);
  //udp.log(true);
  udp.listen(true);

  rectMode(CORNERS);
  ellipseMode(CENTER);
  textFont(createFont("Khmer UI", 100, false));

  comImg = loadImage("comImg2.png");

  reloadMyGui = null;
  removeMyNotification = null;

  notificationsList.add(new Notification("Welcome back!", color(0, 255, 0), 5));

  String timestamp = ZonedDateTime.now(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern( "uuuu_MM_dd-HH_mm_ss" ));
  projectName = "Projname_" + timestamp;

  expandBtn = new Button(new PVector(0, 0), new PVector(width/30, width/25), ">", ">", color(100, 70, 100));

  menuExpLeft = new Expandable(new PVector(0, 0), new PVector(0, 0), "", false, true, CLR_MENU_LV1);
  menuExpLeft.put(new Button(new PVector(0, 0), new PVector(width/20, width/20), "+", "Add\nFixture", CLR_MENU_LV1));
  menuExpLeft.put(new Button(new PVector(0, 0), new PVector(width/20, width/20), "++", "Add\nCuboid", CLR_MENU_LV1));
  menuExpLeft.put(new Button(new PVector(0, 0), new PVector(width/20, width/20), "COM", "Toggle\nNames", CLR_MENU_LV1));
  menuExpLeft.put(new Button(new PVector(0, 0), new PVector(width/20, width/20), "*", "Toggle\nLights", CLR_MENU_LV1));
  menuExpLeft.put(new Button(new PVector(0, 0), new PVector(width/20, width/20), "B", "Toggle\nBeams", CLR_MENU_LV1));
  menuExpLeft.put(new Button(new PVector(0, 0), new PVector(width/20, width/20), "S", "Save\nProject", CLR_MENU_LV1));
  menuExpLeft.put(new NameBox(new PVector(0, 0), new PVector(120, 30), "projectName", "", projectName));

  new File(sketchPath() + PATH_BACKUPS + timestamp + "/fixtures/").mkdirs();             // Create directories for backup
  new File(sketchPath() + PATH_BACKUPS + timestamp + "/projects/").mkdirs();

  // Load fixtures
  Expandable loadFixExp = new Expandable(new PVector(0, 20), new PVector(0, 0), "Fixtures", true, false, CLR_MENU_LV1);
  File dir = new File(sketchPath() + PATH_FIXTURES);
  if (dir.isDirectory()) {
    String names[] = dir.list();
    for (String n : names) {
      try {
        Files.copy(new File(sketchPath() + PATH_FIXTURES + n).toPath(), new File(sketchPath() + PATH_BACKUPS + timestamp + "/fixtures/" + n).toPath(), StandardCopyOption.REPLACE_EXISTING);
      }
      catch(IOException e) {
        notific("Error while auto-backing up Fixtures!", CLR_NOTIF_DANGER, TTL_DANGER);
        println(e);
      }
      loadFixExp.put(new Button(new PVector(0, 0), new PVector(width/12, width/40), "loadfixfilename", n, CLR_MENU_LV2));
    }
  } else {
    notific("Error while scanning fixtures!", CLR_NOTIF_DANGER, TTL_DANGER);
  }
  menuExpLeft.put(loadFixExp);

  // Load environment
  Expandable loadEnvExp = new Expandable(new PVector(0, 0), new PVector(0, 0), "Environments", true, false, CLR_MENU_LV1);
  loadEnvExp.put(new Button(new PVector(0, 0), new PVector(width/12, width/40), "loadenvfilename", "None", CLR_MENU_LV2));
  dir = new File(sketchPath() + PATH_ENVIRONMENTS);
  if (dir.isDirectory()) {
    String names[] = dir.list();
    for (String n : names) {
      if (n.indexOf("env_") != -1) {
        loadEnvExp.put(new Button(new PVector(0, 0), new PVector(width/12, width/40), "loadenvfilename", n, CLR_MENU_LV2));
      }
    }
  } else {
    notific("Error while scanning environments!", CLR_NOTIF_DANGER, TTL_DANGER);
  }
  menuExpLeft.put(loadEnvExp);

  // Load projects
  Expandable loadProjExp = new Expandable(new PVector(0, 0), new PVector(0, 0), "Projects", true, false, CLR_MENU_LV1);
  dir = new File(sketchPath() + PATH_PROJECTS);
  if (dir.isDirectory()) {
    String names[] = dir.list();
    for (String n : names) {
      try {
        Files.copy(new File(sketchPath() + PATH_PROJECTS + n).toPath(), new File(sketchPath() + PATH_BACKUPS + timestamp + "/projects/" + n).toPath(), StandardCopyOption.REPLACE_EXISTING);
      }
      catch(IOException e) {
        notific("Error while auto-backing up Projects!", CLR_NOTIF_DANGER, TTL_DANGER);
        println(e);
      }
      loadProjExp.put(new Button(new PVector(0, 0), new PVector(width/12, width/40), "loadprojfilename", n, CLR_MENU_LV2));
    }
  } else {
    notific("Error while scanning projects!", CLR_NOTIF_DANGER, TTL_DANGER);
  }
  menuExpLeft.put(loadProjExp);


  menuExpRight = new Expandable(new PVector(0, 0), new PVector(0, 0), "", false, true, CLR_MENU_LV1);
}



/// @brief Run cyclically with frameRate (or less) cycles per second
void draw() {
  /********************* 3D Elements ********************/
  background(0);

  if (lightsOff) {
    ambientLight(128, 128, 128);
    directionalLight(128, 128, 128, 0, 0, -1);
  }

  camera(camPos.x, camPos.y, camPos.z, camLookAt.x, camLookAt.y, camLookAt.z, 0, 1, 0);
  fill(255);
  stroke(255);
  strokeWeight(1);
  line(0, -1, 0, 70, -1, 0);
  line(0, -1, 0, 0, -71, 0);
  line(0, -1, 0, 0, -1, 70);
  textSize(height/90);
  text("+X", 80, -10, 0);
  text("-Y", 0, -80, 0);
  text("+Z", 0, -10, 80);
  stroke(0);

  pushMatrix();
  translate(0, 1000, 0);
  stroke(#222222);
  strokeWeight(5);
  fill(#333333);
  box(6000, 2000, 6000);
  popMatrix();

  if (mousePressed) {
    if (mouseButton == RIGHT) {
      camPos = addSphereCoords(PVector.sub(camPos, camLookAt), 0, (pmouseY-mouseY)/100.0, (pmouseX-mouseX)/100.0);
      camPos.add(camLookAt);
    } else if (mouseButton == CENTER) {
      // ToDo this movement behaves a bit unintuitively
      float xzDir = atan2(camPos.z, camPos.x);
      camLookAt.add(new PVector((pmouseX-mouseX)*sin(xzDir), pmouseY-mouseY, -(pmouseX-mouseX)*cos(xzDir)));
      camPos.add(new PVector((pmouseX-mouseX)*sin(xzDir), pmouseY-mouseY, -(pmouseX-mouseX)*cos(xzDir)));
    }
  }

  if (environmentShape != null) {
    pushMatrix();
    noStroke();
    fill(70);
    translate(0, -1, 0);
    shape(environmentShape);
    popMatrix();
  }

  for (Cuboid c : cuboidList) {
    c.display();
  }
  for (Fixture f : fixtureList) {
    f.display();
  }

  if (reloadMyGui != null) {
    println("GUI Reeeeeeloading!");
    menuExpRight.subElementsList.clear();
    reloadMyGui.loadGui();
    reloadMyGui = null;
  }
  if (deleteMyGui) {
    println("Clearing GUI!");
    deleteMyGui = false;
    menuExpRight.subElementsList.clear();
  }
  if (removeMyNotification != null) {
    notificationsList.remove(removeMyNotification);
    removeMyNotification = null;
  }

  /********************* 2D Elements ********************/
  camera();
  hint(DISABLE_DEPTH_TEST);
  fill(255);
  textSize(height/50);
  textAlign(RIGHT, TOP);
  if (frameCount % 15 == 0) {
    calcFrameRate = int(0.8*calcFrameRate + 0.2*(1000/(millis()-lastFrameTime+1)));  // Average about 5 frames
  }
  lastFrameTime = millis();
  text(int(calcFrameRate), width-10, 7);                                        // Print framerate

  if (showNamesAndComs) {
    for (Fixture f : fixtureList) {
      f.draw2d();
    }
    for (Cuboid c : cuboidList) {
      c.draw2d();
    }
  }

  // Menu sidebar
  switch(menuState) {
  case 0:
    break;
  case 1:
    if (abs(menuXpos-(SIZE_MENU_RIGHT+SIZE_MENU_LEFT)) > 0.2) {
      menuXpos += 0.2*((SIZE_MENU_RIGHT+SIZE_MENU_LEFT)-menuXpos);
    } else {
      menuXpos = SIZE_MENU_RIGHT+SIZE_MENU_LEFT;
      menuState = 2;
    }
    break;
  case 2:
    break;
  case 3:
    if (menuXpos > 0.2) {
      menuXpos -= 0.2*menuXpos;
    } else {
      menuXpos = 0;
      menuState = 0;
    }
    break;
  default:
    break;
  }
  stroke(0);
  strokeWeight(2);
  fill(60);
  rect(menuXpos-(SIZE_MENU_RIGHT+SIZE_MENU_LEFT), 0, menuXpos, height);
  if (flag && mousePressed && mouseX>=(menuXpos-SIZE_MENU_RIGHT-10) && mouseX<=(menuXpos-SIZE_MENU_RIGHT+10) && mouseY>=(menuScroll-30) && mouseY<=(menuScroll+30)) {
    flag = false;
    scrolling = true;
  }
  if (scrolling) {
    menuScroll += mouseY-pmouseY;
  }
  menuScroll = constrain(menuScroll, 0, height);
  stroke(0);
  strokeWeight(1);
  fill(100);
  rect(menuXpos-SIZE_MENU_RIGHT-10, menuScroll-30, menuXpos-SIZE_MENU_RIGHT+10, menuScroll+30);
  expandBtn.pos.x = menuXpos;
  expandBtn.display();
  menuExpLeft.pos = PVector.add(new PVector(menuXpos-(SIZE_MENU_LEFT+SIZE_MENU_RIGHT)+20, 20-menuScroll), menuExpLeft.offset);
  menuExpLeft.display();
  menuExpRight.pos = PVector.add(new PVector(menuXpos-(SIZE_MENU_RIGHT)+20, 20-menuScroll), menuExpRight.offset);
  menuExpRight.display();

  if (notificationsList.size() > 0) {
    PVector tempPos = new PVector(width, height);
    tempPos.sub(notificationsList.get(notificationsList.size()-1).size);
    tempPos.sub(new PVector(SIZE_GUTTER, SIZE_GUTTER));
    for (int n=notificationsList.size()-1; n>=0; n--) {
      notificationsList.get(n).pos = PVector.add(tempPos, notificationsList.get(n).offset);
      tempPos.add(new PVector(0, notificationsList.get(n).offset.y));
      tempPos.sub(new PVector(0, notificationsList.get(n).size.y));
      tempPos.sub(new PVector(0, SIZE_GUTTER));
      notificationsList.get(n).display();
    }
  }

  hint(ENABLE_DEPTH_TEST);
}


/// @brief Shorthand for creating Notifications
/// @param iTxt Notification display text
/// @param iClr Notification background color
/// @param iTtl Notification Time-To-Live in seconds
void notific(String iTxt, color iClr, int iTtl) {
  notificationsList.add(new Notification(iTxt, iClr, iTtl));
  println(iTxt);
}



/// @brief Triggered when a mouse button is pressed
void mousePressed() {
  if (mouseButton == LEFT) {
    flag = true;
    selectedScreenObject = null;
    selectedGuiObject = null;
  }
}


/// @brief Triggered when a mouse button is released
void mouseReleased() {
  scrolling = false;
}



/// @brief Triggered when mouse wheel is turned
/// @param event The mouse wheel event
void mouseWheel(MouseEvent event) {
  if (selectedGuiObject != null) {
    selectedGuiObject.editValMouse(event.getCount());
  } else {
    if (menuState == 2  &&  mouseX <= SIZE_MENU_RIGHT+SIZE_MENU_LEFT) {
      menuScroll += 100*event.getCount();
    } else {
      camPos = addSphereCoords(camPos, 80.0*event.getCount(), 0, 0);
    }
  }
}

/// @brief Triggered when keyboard key is pressed
void keyPressed() {
  if (selectedGuiObject != null) {
    selectedGuiObject.editValKey();
  } else if (key == ' ') {
  }
}

/// @brief Saves an entire project, consisting of all Fixtures, Cuboids and the Environment
void saveAll() {
  notific("Saving project " + projectName + "...", CLR_NOTIF_INFO, TTL_SUCCESS);
  JSONObject jsonRoot = new JSONObject();
  int fls = fixtureList.size();
  int cls = cuboidList.size();

  JSONArray jsonFixArray = new JSONArray();
  for (int f=0; f<fls; f++) {
    jsonFixArray.setJSONObject(f, fixtureList.get(f).save());
  }
  jsonRoot.setJSONArray("Fixtures", jsonFixArray);

  JSONArray jsonCubArray = new JSONArray();
  for (int c=0; c<cls; c++) {
    jsonCubArray.setJSONObject(c, cuboidList.get(c).save());
  }
  jsonRoot.setJSONArray("Cuboids", jsonCubArray);

  if (environmentShape != null) {
    JSONObject jsonEnvObj = new JSONObject();
    jsonEnvObj.setString("filename", environmentFileName);
    jsonRoot.setJSONObject("Environment", jsonEnvObj);
  }

  try {
    saveJSONObject(jsonRoot, PATH_PROJECTS + projectName + ".lsm");
    String tempTxt = "Saved " + str(fls) + " Fixtures\nSaved " + str(cls) + " Cuboids";
    if (environmentShape != null) {
      tempTxt += "\nSaved the environment (lol)";
    }
    notific(tempTxt, CLR_NOTIF_SUCCESS, TTL_INFO);
  }
  catch(Exception e) {
    notific("Error while saving " + projectName + "!", CLR_NOTIF_DANGER, TTL_DANGER);
    print(e);
  }
}

/// @brief Loads an entire project, consisting of all Fixtures, Cuboids and the Environment
/// @param iFileName The filename to load
void loadAll(String iFileName) {
  // Commented to try loading multiple projects at once
  //fixtureList.clear();
  //cuboidList.clear();
  //menuExpRight.subElementsList.clear();
  //environmentShape = null;
  //environmentFileName = "";

  int countFix = 0;
  int countCub = 0;
  boolean loadedEnv = false;
  notific("Loading project " + iFileName + "...", CLR_NOTIF_INFO, TTL_SUCCESS);
  try {
    JSONObject jsonLoadRoot = loadJSONObject(PATH_PROJECTS + iFileName);

    JSONArray jsonLoadFixArray = jsonLoadRoot.getJSONArray("Fixtures");
    for (int i=0; i<jsonLoadFixArray.size(); i++) {
      Fixture tempFix = new Fixture();
      tempFix.load(jsonLoadFixArray.getJSONObject(i));
      fixtureList.add(tempFix);
      countFix++;
    }

    JSONArray jsonLoadCubArray = jsonLoadRoot.getJSONArray("Cuboids");
    for (int i=0; i<jsonLoadCubArray.size(); i++) {
      Cuboid tempCub = new Cuboid();
      tempCub.load(jsonLoadCubArray.getJSONObject(i));
      cuboidList.add(tempCub);
      countCub++;
    }
    if (!jsonLoadRoot.isNull("Environment")) {
      JSONObject jsonLoadEnvObj = jsonLoadRoot.getJSONObject("Environment");
      environmentFileName = jsonLoadEnvObj.getString("filename");
      environmentShape = loadShape(sketchPath() + PATH_ENVIRONMENTS + environmentFileName);
      environmentShape.disableStyle();                                          // Ignore the colors in the SVG
      loadedEnv = true;
    }
    String tempTxt = "Loaded " + str(countFix) + " Fixtures\nLoaded " + str(countCub) + " Cuboids";
    if (loadedEnv) {
      tempTxt += "Loaded an environment";
    }
    notific(tempTxt, CLR_NOTIF_SUCCESS, TTL_INFO);
  }
  catch(Exception e) {
    notific("Error while loading project " + iFileName + "!", CLR_NOTIF_DANGER, TTL_DANGER);
    println(e);
  }
}
