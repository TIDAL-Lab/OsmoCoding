library OsmoCoding;

import 'dart:html';
import 'dart:math';
import 'dart:convert';
import 'dart:web_audio';

part 'block.dart';
part 'matrix.dart';
part 'modifier.dart';
part 'parameter.dart';
part 'sounds.dart';
part 'start.dart';
part 'touch.dart';




void main() {
  new CodingWorkspace("workspace", "ws://ntango.sesp.northwestern.edu/ws");
  Sounds.loadSound("click");
  Sounds.loadSound("tick");
}


class CodingWorkspace extends TouchLayer {
  
  /* list of blocks in the workspace */
  //List<Block> blocks = new List<Block>();
  
  /* size of the canvas */
  int width, height;
  
  /* Canvas 2D drawing context */
  CanvasRenderingContext2D ctx;

  /* Start block */
  CodingBlock start;

  /* Touch event manager */
  TouchManager tmanager = new TouchManager();

  List<CodingBlock> blocks = new List<CodingBlock>();

  List<Modifier> modifiers = new List<Modifier>();

  WebSocket socket;
  String server;



/**
 * Construct a code workspace from a JSON object
 */
  CodingWorkspace(String canvasId, this.server) {
    CanvasElement canvas = querySelector("#$canvasId");
    ctx = canvas.getContext('2d');
    width = canvas.width;
    height = canvas.height;
    tmanager.registerEvents(canvas);
    tmanager.addTouchLayer(this);

    num startX = 430;
    num startY = 100;
    num space = 130;

    // REPEAT
    blocks.add(new CodingBlock.byName("repeat", startX, startY + space * 0, this));

    // JUMP
    blocks.add(new CodingBlock.byName("jump", startX, startY + space * 1, this));

    // TOOL
    blocks.add(new CodingBlock.byName("tool", startX, startY + space * 2, this));
    blocks.add(new CodingBlock.byName("tool", startX, startY + space * 2.3, this));

    // WALK
    blocks.add(new CodingBlock.byName("walk", startX, startY + space * 3.3, this));
    blocks.add(new CodingBlock.byName("walk", startX, startY + space * 3.6, this));
    blocks.add(new CodingBlock.byName("walk", startX, startY + space * 3.9, this));
    blocks.add(new CodingBlock.byName("walk", startX, startY + space * 4.2, this));

    // START
    start = new CodingBlock.byName("start", 100, 700, this);
    blocks.add(start);

    // MAGIC
    blocks.add(new CodingBlock.byName("magic", startX, startY + space * 5.2, this));


    startX = 670;
    startY = 100;
    space = 130;
    addModifier(1, startX, startY + space * 0);
    addModifier(2, startX, startY + space * 1);
    addModifier(2, startX + 10, startY + space * 1.3);
    addModifier(3, startX, startY + space * 2.3);
    addModifier(3, startX + 10, startY + space * 2.6);
    addModifier(4, startX, startY + space * 3.6);
    addModifier(4, startX + 10, startY + space * 3.9);
    addModifier(5, startX, startY + space * 4.9);

    draw();
    tick();

    // connect to websocket server
    status("Connecting to $server");
    socket = new WebSocket(server);
    socket.onOpen.listen((e) => status("Connected to $server"));
    socket.onClose.listen((e) => status("Error connecting to $server"));
    socket.onError.listen((e) => status("Error connecting to $server"));

  }


  void addModifier(num value, num x, num y) {
    Modifier modifier = new Modifier(value, x, y, this);
    addTouchable(modifier);
    modifiers.add(modifier);
  }


  void moveToTop(CodingBlock block) {
    blocks.remove(block);
    blocks.add(block);
  }


  void tick() {
    if (animate()) draw();
    window.animationFrame.then((time) => tick());
  }  



/**
 * Animate the blocks and return true if any of the blocks changed
 */
  bool animate() {
    bool refresh = false;
    for (CodingBlock block in blocks) {
      if (block.animate()) refresh = true;
    }
    for (Modifier modifier in modifiers) {
      if (modifier.animate()) refresh = true;
    }
    return refresh;
  }  



  void draw() {
    ctx.save();
    {
      ctx.clearRect(0, 0, width, height);
      modifiers.forEach((modifier) => modifier.draw(ctx));
      blocks.forEach((block) => block.draw(ctx));
    }
    ctx.restore();
  }

 
  void sendCommand(String cmd) {
    var json = { };
    json["command"] = cmd;
    json["blocks"] = [];

    // Find the topmost block in the chain
    CodingBlock block = start;
    while (block.prev != null) { block = block.prev; }

    // Walk down the chain to construct the program as a JSON object
    while (block != null) {
      var b = { };
      b["name"] = block.name;
      if (block.param != null || block.modifier != null) {
        b["parameters"] = [ ];
        if (block.param != null) b["parameters"].add(block.param.toString());
        if (block.modifier != null) b["parameters"].add(block.modifier.value);
      }
      json["blocks"].add(b);
      block = block.next;
    }

    querySelector("#output").innerHtml = getPrettyJSONString(json);

    // Send the command to the websocket server
    if (socket != null && socket.readyState == WebSocket.OPEN) {
      socket.send(JSON.encode(json));
      status("Sent $cmd message to $server");
    } else {
      status("Failed to send $cmd to $server");
    }
  }


  String getPrettyJSONString(jsonObject){
    var encoder = new JsonEncoder.withIndent("  ");
    return encoder.convert(jsonObject);
  }


  void status(String message) {
    querySelector("#status").innerHtml = "Status: $message";
  }  
}
