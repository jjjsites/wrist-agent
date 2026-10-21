import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// Clawd, the Claude Code mascot, in red pixels on a 20x18-unit scene,
// scaled to the screen. One animation per mood: idle, working, waiting,
// happy, and asleep (anything else).
//
// The shape follows the Claude Code icon: a 12x8 body, two 1x2 eye holes,
// 2x2 arms and four 1x2 legs. The screen is black, so an eye hole is a black
// rectangle drawn over the body.
module Face {
    const RED = 0xFF3B30;
    const SHADOW = 0x3A0B08;
    const BANG = 0xFFB020;
    const SPARK = 0xFFD54A;
    const INK = 0xA0A0A0;
    const INK_DIM = 0x505050;

    // Walk speed in units a frame: 15 frames from the middle to either end (±2).
    const WALK = 2.0f / 15;
    const LOOK = [0, -1, 0, 1];
    const JUMP = [0.0f, -0.8f, -1.6f, -2.2f, -2.4f, -2.2f, -1.6f, -0.8f, 0.0f, 0.0f, 0.0f, 0.0f];
    const HOP = [0.0f, -1.5f, -2.5f, -3.0f, -2.5f, -1.5f, 0.0f, 0.0f, 0.0f, 0.0f];
    const LEG_X = [3, 5, 10, 12];
    const ZED = ["####", "..#.", ".#..", "####"];

    const LEGS_STAND = 0;
    const LEGS_WALK_A = 1;
    const LEGS_WALK_B = 2;
    const LEGS_TUCK = 3;
    const LEGS_NONE = 4;

    const EYES_OPEN = 0;
    const EYES_CLOSED = 1;
    const EYES_HAPPY = 2;
    const EYES_WIDE = 3;

    // The scene's top-left corner on the screen, and pixels per unit.
    var _sx as Float = 0.0f;
    var _sy as Float = 0.0f;
    var _u as Float = 1.0f;

    // One frame of Clawd centred on (cx, cy), `unit` pixels to a scene unit.
    // `t` counts frames (10 a second) since the mood began.
    function draw(dc as Graphics.Dc, cx as Number, cy as Number, unit as Number, mood as String,
                  t as Number, blink as Boolean) as Void {
        _u = unit.toFloat();
        _sx = cx - 10 * _u;
        _sy = cy - 9 * _u;

        var bx = 0.0f;
        var by = 0.0f;
        var top = 0;
        var legs = LEGS_STAND;
        var armLT = 4;
        var armLH = 2;
        var armRT = 4;
        var armRH = 2;
        var eyes = EYES_OPEN;
        var look = 0;

        if (mood.equals("idle")) {
            // Walks left and right, stops to look around, waves.
            var c = t % 140;
            var dir = 0;
            if (c < 20) {
                look = LOOK[(c / 5) % 4];
            } else if (c < 35) {
                bx = (c - 20) * WALK;
                dir = 1;
            } else if (c < 60) {
                bx = 2.0f;
                look = LOOK[(c / 6) % 4];
            } else if (c < 90) {
                bx = 2.0f - (c - 60) * WALK;
                dir = -1;
            } else if (c < 115) {
                bx = -2.0f;
                look = LOOK[(c / 6) % 4];
            } else if (c < 130) {
                bx = -2.0f + (c - 115) * WALK;
                dir = 1;
            } else if ((c / 3) % 2 == 0) {
                armRT = -2;
                armRH = 5;
            }
            if (dir != 0) {
                legs = (c / 2) % 2 == 0 ? LEGS_WALK_A : LEGS_WALK_B;
                look = dir;
            }
        } else if (mood.equals("working")) {
            // Types with both arms, bobs, eyes scan, three dots count up.
            by = t % 4 < 2 ? 0.0f : -0.5f;
            if ((t / 2) % 2 == 0) {
                armLT = 3;
                armRT = 5;
            } else {
                armLT = 5;
                armRT = 3;
            }
            look = (t / 9) % 2 == 0 ? -1 : 1;
        } else if (mood.equals("waiting")) {
            // Jumps with its arms up under an amber "!".
            var c = t % 12;
            by = JUMP[c] as Float;
            if (by < 0) {
                legs = LEGS_TUCK;
                armLT = -2;
                armLH = 5;
                armRT = -2;
                armRH = 5;
            }
            if (c == 8) {
                top = 1;
            }
            eyes = EYES_WIDE;
        } else if (mood.equals("happy")) {
            // Hops and waves, ^ ^ eyes, gold sparkles.
            by = HOP[t % 10] as Float;
            if (by < 0) {
                legs = LEGS_TUCK;
            }
            if ((t / 2) % 2 == 0) {
                armLT = -2;
                armLH = 5;
            } else {
                armRT = -2;
                armRH = 5;
            }
            eyes = EYES_HAPPY;
        } else {
            // Asleep: sits, closed eyes, breathes, z's rise.
            by = 2.0f;
            legs = LEGS_NONE;
            top = (t / 12) % 2;
            armLT = 5;
            armRT = 5;
            eyes = EYES_CLOSED;
        }
        if (eyes == EYES_OPEN && blink) {
            eyes = EYES_CLOSED;
        }

        var ox = 2 + bx;
        var oy = 7 + by;

        dc.setColor(SHADOW, Graphics.COLOR_TRANSPARENT);
        var air = by < 0 ? -by : 0.0f;
        var sw = 12 - air * 2;
        fill(dc, ox + 8 - sw / 2, 17.25f, sw, 0.75f);

        dc.setColor(RED, Graphics.COLOR_TRANSPARENT);
        if (legs != LEGS_NONE) {
            for (var i = 0; i < 4; i++) {
                var up = legs == LEGS_TUCK || (legs == LEGS_WALK_A && i % 2 == 0) || (legs == LEGS_WALK_B && i % 2 == 1);
                fill(dc, ox + LEG_X[i], oy + 8, 1, up ? 1 : 2);
            }
        }
        fill(dc, ox, oy + armLT, 2, armLH);
        fill(dc, ox + 14, oy + armRT, 2, armRH);
        fill(dc, ox + 2, oy + top, 12, 8 - top);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 2; i++) {
            var c = (i == 0 ? 4 : 11) + look;
            if (eyes == EYES_OPEN) {
                fill(dc, ox + c, oy + 2, 1, 2);
            } else if (eyes == EYES_WIDE) {
                fill(dc, ox + c, oy + 1, 1, 3);
            } else if (eyes == EYES_CLOSED) {
                fill(dc, ox + c - 1, oy + 3, 3, 1);
            } else {
                fill(dc, ox + c - 1, oy + 3, 1, 1);
                fill(dc, ox + c, oy + 2, 1, 1);
                fill(dc, ox + c + 1, oy + 3, 1, 1);
            }
        }

        if (mood.equals("working")) {
            dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
            var dots = (t / 3) % 4;
            for (var i = 0; i < dots; i++) {
                fill(dc, 7 + i * 2.5f, 4, 1, 1);
            }
        } else if (mood.equals("waiting")) {
            if (t % 8 < 6) {
                dc.setColor(BANG, Graphics.COLOR_TRANSPARENT);
                fill(dc, 9.5f, 0, 1, 2.5f);
                fill(dc, 9.5f, 3, 1, 0.8f);
            }
        } else if (mood.equals("happy")) {
            dc.setColor(SPARK, Graphics.COLOR_TRANSPARENT);
            if ((t / 3) % 2 == 0) {
                spark(dc, 5.5f, 1.8f);
                spark(dc, 14.5f, 1.8f);
            } else {
                spark(dc, 10.0f, 1.5f);
            }
        } else if (!mood.equals("idle")) {
            for (var k = 0; k < 2; k++) {
                var p = ((t + k * 15) % 30) / 30.0f;
                var s = 0.55f + p * 0.3f;
                // The screen has no alpha: a z fades by stepping to a dim grey.
                dc.setColor(p < 0.5f ? INK : INK_DIM, Graphics.COLOR_TRANSPARENT);
                for (var ry = 0; ry < 4; ry++) {
                    var row = ZED[ry] as String;
                    for (var rx = 0; rx < 4; rx++) {
                        if (row.substring(rx, rx + 1).equals("#")) {
                            fill(dc, 13 + p * 2 + rx * s, 7 - p * 6 + ry * s, s, s);
                        }
                    }
                }
            }
        }
    }

    // A gold plus, 3 units across, centred on (x, y).
    function spark(dc as Graphics.Dc, x as Float, y as Float) as Void {
        fill(dc, x - 0.5f, y - 1.5f, 1, 3);
        fill(dc, x - 1.5f, y - 0.5f, 3, 1);
    }

    // A rectangle in scene units. Both edges round to the pixel grid, so two
    // rectangles that touch in units never leave a seam on the screen.
    function fill(dc as Graphics.Dc, x as Numeric, y as Numeric, w as Numeric, h as Numeric) as Void {
        var x0 = px(_sx + x * _u);
        var y0 = px(_sy + y * _u);
        var x1 = px(_sx + (x + w) * _u);
        var y1 = px(_sy + (y + h) * _u);
        if (x1 > x0 && y1 > y0) {
            dc.fillRectangle(x0, y0, x1 - x0, y1 - y0);
        }
    }

    function px(v as Float) as Number {
        return Math.floor(v + 0.5f).toNumber();
    }
}
