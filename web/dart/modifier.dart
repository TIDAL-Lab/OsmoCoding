part of OsmoCoding;

class Modifier extends Touchable {
  

  num value = 2;

  CodingWorkspace workspace;

  bool _dragging = false;
  num _touchX, _touchY, _lastX, _lastY;

  String background = "#ffcc00";
  String foreground = "rgb(102, 102, 102)";
  num x, y;
  num w = 70;
  num h = BLOCK_HEIGHT - 8;

  CodingBlock block = null;

  ImageElement image = new ImageElement();

  Modifier(this.value, this.x, this.y, this.workspace) {
    image.src = "images/$value.png";
  }


  num get centerY => y + h/2;
  set centerY(num cy) { y = cy - h/2; }
  num get centerX => x + w/2;
  num get rightConnectorY => centerY;
  num get rightConnectorX => x;


  bool animate() { return _dragging; }


  bool nearConnector(CodingBlock other) {
    if (block == null && other.rightConnector && other.modifier == null) {
      return ((rightConnectorY - other.rightConnectorY).abs() <= 20 &&
              (rightConnectorX - other.rightConnectorX).abs() <= 20);
    }
    return false;
  }


  CodingBlock findConnection() {
    for (CodingBlock other in workspace.blocks) {
      if (nearConnector(other)) return other;
    }
    return null;
  }


  bool highlightConnector() => (_dragging && findConnection() != null);


  bool connectToBlock() {
    CodingBlock b = findConnection();
    if (b != null) {
      block = b;
      block.modifier = this;
      block.straighten();
      y = block.blockY;
      x = block.rightConnectorX;
      return true;
    }
    return false;
  }


  void draw(CanvasRenderingContext2D ctx) {
    num br = 30 * 0.85;
    ctx.save();
    {
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + w - br, y);
      ctx.quadraticCurveTo(x + w, y, x + w, y + br);
      ctx.lineTo(x + w, y + h - br);
      ctx.quadraticCurveTo(x + w, y + h, x + w - br, y + h);
      ctx.lineTo(x, y + h);
      ctx.lineTo(x, y + h - 12);
      ctx.arc(x - 16, y + h/2, h/2 - 8, PI * 0.32, -PI * 0.32, true);
      ctx.lineTo(x, y + 12);
      ctx.closePath();

      ctx.save();
      {
        if (block == null) {
          ctx.shadowOffsetX = 0;
          ctx.shadowOffsetY = 0;
          ctx.shadowBlur = 10;
          ctx.shadowColor = "rgba(0, 0, 0, 0.6)";
        }
        ctx.fillStyle = background;
        ctx.fill();
      }
      ctx.restore();
      ctx.strokeStyle = "white";
      ctx.lineWidth = highlightConnector() ? 5 : 2;
      ctx.stroke();
      num iw = image.width * 0.85;
      num ih = image.height * 0.85;
      ctx.drawImageScaled(image, x + w * 0.4, y + h/2 - ih/2, iw, ih);
    }
    ctx.restore();
  }


  bool containsTouch(Contact c) {
    return (c.touchX >= x && c.touchX <= x + w && c.touchY >= y && c.touchY <= y + h);
  }


  bool touchDown(Contact c) {
    _dragging = true;
    _touchX = c.touchX;
    _touchY = c.touchY;
    _lastX = c.touchX;
    _lastY = c.touchY;
    if (block != null) {
      block.modifier = null;
      CodingBlock target = block;
      block = null;
      workspace.sendCommand("changed", target);
    }
    return true;
  }


  void touchUp(Contact c) {
    if (connectToBlock()) {
      workspace.sendCommand("changed", block);
      Sounds.playSound("click");
    }
    workspace.draw();
    _dragging = false;
  }


  void touchDrag(Contact c) {
    _touchX = c.touchX;
    _touchY = c.touchY;
    x += (_touchX - _lastX);
    y += (_touchY - _lastY);
    _lastX = c.touchX;
    _lastY = c.touchY;
  }


  void touchSlide(Contact c) { }
}