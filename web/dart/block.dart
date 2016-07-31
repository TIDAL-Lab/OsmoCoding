part of OsmoCoding;


const BLOCK_WIDTH = 170; //200;
const BLOCK_HEIGHT = 85; //100;
const BLOCK_SCALE = 0.85;
const TOP_MODE = true;


class CodingBlock extends Touchable {

  String name = "block";

  CodingBlock next = null;

  CodingBlock prev = null;

  num _width = BLOCK_WIDTH;

  bool topConnector = true;
  bool bottomConnector = true;
  bool rightConnector = false;

  Parameter param = null;

  Modifier modifier = null;

  String color = "rgb(0, 160, 227)";

  ImageElement _img = new ImageElement();

  ControlPoint _cp0, _cp1, _cp2, _target;

  CodingWorkspace workspace;


  factory CodingBlock.byName(String name, num x, num y, CodingWorkspace workspace) {
    switch(name) {
    case "start":  return new StartBlock(x, y, workspace);

    case "tool":
    return new CodingBlock("tool", x, y, "rgb(255, 102, 0)", true, true, workspace);

    case "magic":
    return new CodingBlock("magic", x, y, "rgb(229, 0, 173)", false, false, workspace);

    case "jump":
    return new CodingBlock("jump", x, y, "red", true, true, workspace);

    case "repeat":
    return new CodingBlock("repeat", x, y, "rgb(210, 208, 205)", false, true, workspace) .. topConnector = false;

    default:
    return new CodingBlock("walk", x, y, "rgb(0, 160, 227)", true, true, workspace);
    }
  }


  CodingBlock(this.name, num x, num y, this.color, bool hasParam, this.rightConnector, this.workspace) {
    _img.src = "images/$name.png";
    _img.onLoad.listen((e) => workspace.draw());
    _width = rightConnector ? BLOCK_WIDTH : BLOCK_WIDTH + 50;
    num cw = _width / 3;
    num ch = BLOCK_HEIGHT;
    _cp0 = new ControlPoint(x + cw/2, y + BLOCK_HEIGHT / 2, cw, ch, workspace);
    _cp1 = new ControlPoint(x + _width / 2, y + BLOCK_HEIGHT / 2, cw, ch, workspace);
    _cp2 = new ControlPoint(x + _width - cw/2, y + BLOCK_HEIGHT / 2, cw, ch, workspace);
    workspace.addTouchable(this);
    if (hasParam) {
      param = new Parameter(this);
      workspace.addTouchable(param);
      rightConnector = true;
    }
  }


  bool get dragging {
    if (TOP_MODE) {
      return (_target != null || (prev != null && prev.dragging));
    } else {
      return (_target != null || (next != null && next.dragging));
    }
  }


  num get blockX => centerX - _width / 2;
  num get blockY => centerY - BLOCK_HEIGHT / 2;
  num get centerX => _cp1.cx;
  num get centerY => _cp1.cy;
  num get rotation => _cp2.angle(_cp0);


  void straighten() {
    _cp0.cx = _cp1.cx - _cp1.cw;
    _cp2.cx = _cp1.cx + _cp1.cw;
    _cp0.cy = _cp2.cy = _cp1.cy;
  }


  bool nearBottomConnector(CodingBlock other) {
    if (other != this && other.bottomConnector && topConnector && other.next == null && prev == null) {
      return ((topConnectorX - other.bottomConnectorX).abs() <= 20 &&
              (topConnectorY - other.bottomConnectorY).abs() <= 20);
    }
    return false;
  }


  bool nearTopConnector(CodingBlock other) {
    return other.nearBottomConnector(this);
  }


  bool nearRightConnector(Modifier mod) {
    if (modifier == null && rightConnector && mod.block == null) {
      return ((rightConnectorY - mod.rightConnectorY).abs() <= 20 &&
              (rightConnectorX - mod.rightConnectorX).abs() <= 20);
    }
    return false;
  }


  CodingBlock findTopConnection() {
    if (topConnector) {
      for (CodingBlock other in workspace.blocks) {
        if (other != this) {
          if (nearBottomConnector(other)) return other;
        }
      }
    }
    return null;
  }


  CodingBlock findBottomConnection() {
    if (bottomConnector) {
      for (CodingBlock other in workspace.blocks) {
        if (other != this) {
          if (nearTopConnector(other)) return other;
        }
      }
    }
    return null;
  }


  Modifier findRightConnection() {
    if (rightConnector) {
      for (Modifier mod in workspace.modifiers) {
        if (nearRightConnector(mod)) return mod;
      }
    }
    return null;
  }


  bool highlightTopConnector() => (dragging && findTopConnection() != null);

  bool highlightBottomConnector() => (dragging && findBottomConnection() != null);


  void dockBelow(CodingBlock other) {
    if (other.next == null && prev == null) {
      other.straighten();
      straighten();
      moveChain(other.bottomConnectorX - bottomConnectorX, other._cp0.cy + BLOCK_HEIGHT - 8 - _cp0.cy, false);
      other.next = this;
      prev = other;
    }
  }


  void dockAbove(CodingBlock other) {
    if (other.prev == null && next == null) {
      other.straighten();
      straighten();
      moveChain(other.bottomConnectorX - bottomConnectorX, other._cp0.cy - BLOCK_HEIGHT + 8 - _cp0.cy);
      other.prev = this;
      next = other;
    }
  }


  void dockRight(Modifier mod) {
    if (modifier == null && mod.block == null) {
      straighten();
      modifier = mod;
      mod.block = this;
      mod.y = blockY;
      mod.x = rightConnectorX;
    }
  }


  bool connectBlocks() {
    CodingBlock top = findTopConnection();
    CodingBlock bot = findBottomConnection();
    bool changed = false;
    if (top != null) {
      dockBelow(top);
      changed = true;
    } 
    if (bot != null) {
      dockAbove(bot);
      changed = true;
    }
    CodingBlock topmost = this;
    while (topmost.prev != null) topmost = topmost.prev;
    top = topmost.findTopConnection();
    if (top != null) {
      topmost.dockBelow(top);
      changed = true;
    }

    CodingBlock bottommost = this;
    while (bottommost.next != null) bottommost = bottommost.next;
    bot = bottommost.findBottomConnection();
    if (bot != null) {
      bottommost.dockAbove(bot);
      changed = true;
    }

    Modifier mod = findRightConnection();
    if (mod != null) {
      dockRight(mod);
      changed = true;
    }

    if (changed) Sounds.playSound("click");
    return changed;
  }


  void draw(CanvasRenderingContext2D ctx) {

    num cx = _cp1.cx;
    num cy = _cp1.cy;
    num theta = _cp2.angle(_cp0);

    ctx.save();
    {
      ctx.translate(cx, cy);
      ctx.rotate(-theta);
      num bx = _width / -2;
      num by = BLOCK_HEIGHT / -2;
      num bw = _width;
      num bh = BLOCK_HEIGHT - 8;
      _blockOutline(ctx, bx, by, bw, bh);
      ctx.save();
      {
        if (prev == null && next == null && modifier == null) {
          ctx.shadowOffsetX = 0;
          ctx.shadowOffsetY = 0;
          ctx.shadowBlur = 10;
          ctx.shadowColor = "rgba(0, 0, 0, 0.6)";
        }
        ctx.fillStyle = color;
        ctx.fill();
      }
      ctx.restore();

      ctx.strokeStyle = "white";
      ctx.lineWidth = 2;
      ctx.stroke();
      if (param != null) {
        param.draw(ctx);
      }

      if (_img != null) {
        num iw = _img.width * BLOCK_SCALE;
        num ih = _img.height * BLOCK_SCALE;
        num ix = iw / -2;
        num iy = ih / -2 - 5;
        if (param != null) {
          ix -= 20;
        } else if (rightConnector) {
          ix -= 10;
        }

        ctx.drawImageScaled(_img, ix, iy, iw, ih);
      }
    }
    ctx.restore();

    if (highlightTopConnector()) {
      ctx.fillStyle = "rgba(255, 255, 255, 0.8)";
      ctx.beginPath();
      ctx.arc(topConnectorX, topConnectorY, 15, 0, PI * 2, true);
      ctx.fill();
    }

    if (highlightBottomConnector()) {
      ctx.fillStyle = "rgba(255, 255, 255, 0.8)";
      ctx.beginPath();
      ctx.arc(bottomConnectorX, bottomConnectorY, 15, 0, PI * 2, true);
      ctx.fill();
    }
    //_cp0.draw(ctx);
    //_cp1.draw(ctx);
    //_cp2.draw(ctx);
  }


  void moveChain(num dx, num dy, [bool up = true]) {
    if (_target != _cp0) {
      _cp0.cx += dx;
      _cp0.cy += dy;
    }
    if (_target != _cp1) {
      _cp1.cx += dx;
      _cp1.cy += dy;
    }
    if (_target != _cp2) {
      _cp2.cx += dx;
      _cp2.cy += dy;
    }
    if (modifier != null) {
      modifier.x += dx;
      modifier.y += dy;
    }
    if (up) {
      if (prev != null) prev.moveChain(dx, dy, up);
    } else {
      if (next != null) next.moveChain(dx, dy, up);
    }
  }


  bool animate() { 
    bool refresh = false;
    if (_cp0.animate()) refresh = true;
    if (_cp1.animate()) refresh = true;
    if (_cp2.animate()) refresh = true;
    if (param != null && param.animate()) refresh = true;

    if (_target != null && ((TOP_MODE && next != null) || (!TOP_MODE && prev != null) || (modifier != null))) {
      moveChain(_target._deltaX, _target._deltaY, !TOP_MODE);
    }
    else if (_cp2._dragging) {
      _cp2.pull(_cp0);
      _cp1.cx = (_cp0.cx + _cp2.cx) / 2;
      _cp1.cy = (_cp0.cy + _cp2.cy) / 2;
    }
    else if (_cp0._dragging) {
      _cp0.pull(_cp2);
      _cp1.cx = (_cp0.cx + _cp2.cx) / 2;
      _cp1.cy = (_cp0.cy + _cp2.cy) / 2;
    }
    else if (_cp1._dragging) {
      _cp0.cx += _cp1._deltaX;
      _cp0.cy += _cp1._deltaY;
      _cp2.cx += _cp1._deltaX;
      _cp2.cy += _cp1._deltaY;
    }

    return refresh;
  }


  num get rightConnectorX {
    return blockX + _width - 22;
  }

  num get rightConnectorY {
    return centerY;
  }


  num get bottomConnectorX {
    if (rightConnector) {
      return centerX + sin(rotation - PI * .16) * BLOCK_HEIGHT * .52;
    } else {
      return centerX + sin(rotation - PI * .27) * BLOCK_HEIGHT * .72;
    }
  }

  num get bottomConnectorY {
    if (rightConnector) {
      return centerY + cos(rotation - PI * .16) * BLOCK_HEIGHT * .52;
    } else {
      return centerY + cos(rotation - PI * .27) * BLOCK_HEIGHT * .72;
    }
  }

  num get topConnectorX {
    if (rightConnector) {
      return centerX - sin(rotation + PI * .16) * BLOCK_HEIGHT * .55;
    } else {
      return centerX - sin(rotation + PI * .27) * BLOCK_HEIGHT * .72;
    }
  }

  num get topConnectorY {
    if (rightConnector) {
      return centerY - cos(rotation + PI * .16) * BLOCK_HEIGHT * .55;
    } else {
      return centerY - cos(rotation + PI * .27) * BLOCK_HEIGHT * .72;
    }
  }


  bool containsTouch(Contact c) {
    return (_cp0.containsTouch(c) || _cp1.containsTouch(c) || _cp2.containsTouch(c));
  }


  bool _disconnected = false;
 

  bool touchDown(Contact c) {
    _disconnected = false;

    if (TOP_MODE && prev != null) {
      prev.next = null;
      prev = null;
      _disconnected = true;
    }

    if (!TOP_MODE && next != null) {
      next.prev = null;
      next = null;
      _disconnected = true;
    }

    _target = null;
    if (_cp0.containsTouch(c)) {
      _target = _cp0;
      _target.touchDown(c);
    } else if (_cp2.containsTouch(c)) {
      _target = _cp2;
      _target.touchDown(c);
    } else if (_cp1.containsTouch(c)) {
      _target = _cp1;
      _target.touchDown(c);
    }

    if (_target != null) {
      CodingBlock topmost = this;
      while (topmost.prev != null) topmost = topmost.prev;
      while (topmost != null) {
        workspace.moveToTop(topmost);
        topmost = topmost.next;
      }
    }
    return _target != null;
  }


  void touchUp(Contact c) { 
    if (_target != null) _target.touchUp(c);
    _target = null;
    if (connectBlocks() || prev != null || next != null || !_disconnected) {
      workspace.sendCommand("changed", this);
    }
    workspace.draw();
  }
 

  void touchDrag(Contact c) {
    if (_target != null) {
      _target.touchDrag(c);
    }
  }
   
  void touchSlide(Contact event) {  }


  void _blockOutline(CanvasRenderingContext2D ctx, num bx, num by, num bw, num bh) {
    num br = 30 * BLOCK_SCALE;
    num notch = 67 * BLOCK_SCALE;
    num nw = 14;
    num nh = 8;
    ctx.beginPath();
    ctx.moveTo(bx + br, by);
    if (topConnector) {
      ctx.lineTo(bx + notch, by);
      ctx.quadraticCurveTo(bx + notch, by + nh, bx + notch + nw/2, by + nh);
      ctx.quadraticCurveTo(bx + notch + nw, by + nh, bx + notch + nw, by);
    }
    if (rightConnector) {
      ctx.lineTo(bx + bw - 22, by);
      ctx.lineTo(bx + bw - 22, by + 12);
      ctx.arc(bx + bw - 32, by + bh/2, bh/2 - 12, -PI * 0.37, PI * 0.37, false);
      ctx.lineTo(bx + bw - 22, by + bh - 12);
      ctx.lineTo(bx + bw - 22, by + bh);
    } else {
      ctx.lineTo(bx + bw - br, by);
      ctx.quadraticCurveTo(bx + bw, by, bx + bw, by + br);
      ctx.lineTo(bx + bw, by + bh - br);
      ctx.quadraticCurveTo(bx + bw, by + bh, bx + bw - br, by + bh);
    }

    if (bottomConnector) {
      ctx.lineTo(bx + notch + nw, by + bh);
      ctx.quadraticCurveTo(bx + notch + nw, by + bh + nh, bx + notch + nw/2, by + bh + nh);
      ctx.quadraticCurveTo(bx + notch, by + bh + nh, bx + notch, by + bh);
    }
    ctx.lineTo(bx + br, by + bh);
    ctx.quadraticCurveTo(bx, by + bh, bx, by + bh - br);
    ctx.lineTo(bx, by + br);
    ctx.quadraticCurveTo(bx, by, bx + br, by);
    ctx.closePath();    
  }

}


class ControlPoint extends Touchable {

  num cx, cy, cw, ch;

  CodingWorkspace workspace;

  bool _dragging;
  num _lastX, _lastY;
  num _touchX, _touchY;
  num _deltaX, _deltaY;

  ControlPoint(this.cx, this.cy, this.cw, this.ch, this.workspace);


  num distance(ControlPoint other) {
    return sqrt((other.cx - cx) * (other.cx - cx) + (other.cy - cy) * (other.cy - cy));
  }

  num angle(ControlPoint other) {
    return atan2(other.cy - cy, cx - other.cx); 
  }


  void pull(ControlPoint other) {
    num dist = distance(other) - (cw * 2);
    num theta = angle(other);
    if ((theta % PI) < 0.2 || (theta % PI) > PI - 0.2) {
      other.cx += dist * cos(theta);
      other.cy -= dist * sin(theta);
    } else {
      other.cx += _deltaX;
      other.cy += _deltaY;
    }
  }


  void draw(CanvasRenderingContext2D ctx) {
    ctx.fillStyle = "rgba(255, 255, 255, 0.5)";
    ctx.beginPath();
    ctx.fillRect(cx - cw/2, cy - ch/2, cw, ch);
  }


  bool animate() {
    if (_dragging) {
      _deltaX = (_touchX - _lastX);
      _deltaY = (_touchY - _lastY);
      cx += _deltaX;
      cy += _deltaY;
      _lastX = _touchX;
      _lastY = _touchY;
    }
    return _dragging;
  }

  bool containsTouch(Contact c) {
    return (c.touchX >= cx - cw/2 && c.touchX <= cx + cw/2 &&
            c.touchY >= cy - ch/2 && c.touchY <= cy + ch/2);
  }
 

  bool touchDown(Contact c) {
    _dragging = true;
    _touchX = c.touchX;
    _touchY = c.touchY;
    _lastX = c.touchX;
    _lastY = c.touchY;
    return true;
  }


  void touchUp(Contact event) { 
    _dragging = false;
    workspace.draw();
  }
 

  void touchDrag(Contact c) {
    _touchX = c.touchX;
    _touchY = c.touchY;
  }
   
  void touchSlide(Contact event) {  }

}
