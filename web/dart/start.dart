part of OsmoCoding;


class StartBlock extends CodingBlock {

  PlayButton button;

  StartBlock(num x, num y, CodingWorkspace workspace) : 
    super("start", x, y, "rgb(0, 191, 99)", false, false, workspace) 
  {
    bottomConnector = false;
    button = new PlayButton(this);
    _img = null;
    workspace.addTouchable(button);
  }


  void draw(CanvasRenderingContext2D ctx) {
    super.draw(ctx);
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      ctx.rotate(-rotation);
      button.draw(ctx);
    }
    ctx.restore();
  }


  bool animate() { 
    bool refresh = false;
    if (super.animate()) refresh = true;
    if (button.animate()) refresh = true;
    return refresh;
  }
}


class PlayButton extends Touchable {
  
  StartBlock start;
  bool down = false;
  num x, y, w, h;

  ImageElement img = new ImageElement();

  PlayButton(this.start) {
    img.src = "images/start.png";
  }

  bool animate() {
    return down;
  }

  void draw(CanvasRenderingContext2D ctx) {
    w = img.width * 0.85;
    x = start.centerX - w/2 + 6;
    h = img.height * 0.85;
    y = start.centerY - h/2 - 3;
    num ix = -w/2 + 6;
    num iy = -h/2 - 3;
    ctx.save();
    if (down) {ctx.globalAlpha = 0.5; }
    ctx.drawImageScaled(img, ix, iy, w, h);
    ctx.restore();
  }


  bool containsTouch(Contact c) {
    return (c.touchX >= x && c.touchX <= x + w && c.touchY >= y && c.touchY <= y + h);
  }

  bool touchDown(Contact c) { 
    start.workspace.sendCommand("play");
    down = true; 
    return true; 
  }
  void touchUp(Contact c) { 
    down = false; 
    start.workspace.draw(); 
    start.workspace.sendCommand("stop");
  }
  void touchDrag(Contact c) {  }
  void touchSlide(Contact c) {  }
}
