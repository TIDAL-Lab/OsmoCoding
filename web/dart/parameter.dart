part of OsmoCoding;

class Parameter extends Touchable {
  

  num _angle = PI/2;
  num _target_angle = PI/2;

  String background = "rgb(204, 204, 204)";
  String foreground = "rgb(102, 102, 102)";

  CodingBlock block;

  Parameter(this.block);


  String toString() {
    num a = _target_angle % (PI * 2);
    if (a == 0) {
      return "up";
    } else if (a == PI) {
      return "down";
    } else if (a == PI/2) {
      return "right";
    } else {
      return "left";
    }
  }


  bool animate() {
    if (_angle != _target_angle) {
      num delta = _target_angle - _angle;
      if (delta.abs() < 0.05) {
        if (_target_angle >= PI * 2) _target_angle = 0.0;
        _angle = _target_angle;
        Sounds.playSound("tick");
      }
      else if (delta > 0) {
        _angle += delta * 0.3;
      } else {
        _angle -= delta * 0.3;
      }
      return true;
    } else {
      return false;
    }
  }


  void draw(CanvasRenderingContext2D ctx) {
    num px = BLOCK_WIDTH / 2 - 32;
    num py = -4;
    num pr = 32;
    ctx.save();
    {
      ctx.translate(px, py);
      ctx.rotate(_angle);
      ctx.translate(-px, -py);
      ctx.beginPath();
      ctx.arc(px, py, pr, 0, PI * 2, true);
      ctx.save();
      {
        ctx.shadowOffsetX = 0;
        ctx.shadowOffsetY = 0;
        ctx.shadowBlur = 10;
        ctx.shadowColor = "rgba(0, 0, 0, 0.2)";
        ctx.fillStyle = "rgb(204, 204, 204)";
        ctx.fill();
      }
      ctx.restore();
      ctx.strokeStyle = "rgba(0, 0, 0, 0.2)";
      ctx.lineWidth = 1;
      ctx.stroke();

      ctx.beginPath();
      ctx.moveTo(px, py - 22);
      ctx.lineTo(px - 12, py - 4);
      ctx.lineTo(px + 12, py - 4);
      ctx.closePath();
      ctx.fillStyle = "rgb(102, 102, 102)";
      ctx.fill();

      ctx.beginPath();
      ctx.moveTo(px, py - 8);
      ctx.lineTo(px, py + 18);
      ctx.lineWidth = 8;
      ctx.strokeStyle = "rgb(102, 102, 102)";
      ctx.stroke();
    }
    ctx.restore();
  }


  bool containsTouch(Contact c) {
    num px = block.centerX + BLOCK_WIDTH / 2 - 32;
    num py = block.centerY - 4;
    num pr = 35;
    return (c.touchX >= px - pr &&
            c.touchX <= px + pr &&
            c.touchY >= py - pr &&
            c.touchY <= py + pr);
  }


  bool touchDown(Contact c) {
    return true;
  }


  void touchUp(Contact c) {
    _target_angle += PI / 2;
    block.workspace.sendCommand("changed", block);
  }


  void touchDrag(Contact c) {  }


  void touchSlide(Contact c) { }
}