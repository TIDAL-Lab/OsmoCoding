part of OsmoCoding;



void roundRect(CanvasRenderingContext2D ctx, num x, num y, num w, num h, num r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}


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
    w = img.width * BLOCK_SCALE;
    x = start.centerX - w/2;
    h = img.height * BLOCK_SCALE;
    y = start.centerY - h/2;
    num ix = -w/2;
    num iy = -h/2;
    ctx.save();
    if (down) {ctx.globalAlpha = 0.5; }
    ctx.drawImageScaled(img, ix, iy, w, h);
    ctx.restore();
    ctx.fillStyle = "white";
    roundRect(ctx, -95, -32, 48, 18, 10);
    ctx.fill();
    roundRect(ctx, w + 2, -32, 48, 18, 10);
    ctx.fill();
    if (down) {
      ctx.fillStyle = "black";
      roundRect(ctx, -90, -28, 38, 10, 5);
      ctx.fill();
      roundRect(ctx, w + 7, -28, 38, 10, 5);
      ctx.fill();
    }
  }


  bool containsTouch(Contact c) {
    return (c.touchX >= x && c.touchX <= x + w && c.touchY >= y && c.touchY <= y + h);
  }

  bool touchDown(Contact c) { 
    start.workspace.sendCommand("play", start);
    down = true; 
    return true; 
  }
  void touchUp(Contact c) { 
    down = false; 
    start.workspace.draw(); 
    start.workspace.sendCommand("stop", start);
  }
  void touchDrag(Contact c) {  }
  void touchSlide(Contact c) {  }
}
