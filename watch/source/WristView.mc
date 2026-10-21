import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// The home screen: the clock, Clawd acting out the mood, and the last line
// on the Claude Code screen. Animated at 10 frames a second while visible.
class WristView extends WatchUi.View {
    hidden var _anim as Timer.Timer?;
    hidden var _tick as Number = 0;
    hidden var _nextBlink as Number = 30;
    hidden var _blinkLeft as Number = 0;
    hidden var _frame as Number = 0;
    hidden var _mood as String = "";

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        var t = new Timer.Timer();
        t.start(method(:onTick), 100, true);
        _anim = t;
    }

    function onHide() as Void {
        if (_anim != null) {
            _anim.stop();
        }
        _anim = null;
    }

    function onTick() as Void {
        _tick++;
        var mood = (Application.getApp() as WristApp).faceMood();
        // Each mood starts from its first frame.
        if (mood.equals(_mood)) {
            _frame++;
        } else {
            _mood = mood;
            _frame = 0;
        }
        // Blink at uneven intervals.
        if (_blinkLeft > 0) {
            _blinkLeft--;
        } else if (_tick >= _nextBlink) {
            _blinkLeft = 2;
            _nextBlink = _tick + 22 + (Math.rand() % 38);
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var app = Application.getApp() as WristApp;
        var w = dc.getWidth();
        var h = dc.getHeight();
        var mood = app.faceMood();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var clock = System.getClockTime();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.09).toNumber(), Graphics.FONT_TINY,
            clock.hour.format("%02d") + ":" + clock.min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);

        Face.draw(dc, w / 2, h / 2 - 4, (w * 0.62 / 20).toNumber(), mood, _frame, _blinkLeft > 0);

        dc.setColor(mood.equals("waiting") ? 0xFFB020 : 0xFF3B30, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.79).toNumber(), Graphics.FONT_XTINY, moodText(mood), Graphics.TEXT_JUSTIFY_CENTER);

        var n = app.tail.size();
        if (n > 0) {
            var line = app.tail[n - 1] as String;
            if (line.length() > 24) {
                line = line.substring(0, 24);
            }
            dc.setColor(0x8A8A8A, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 0.87).toNumber(), Graphics.FONT_XTINY, line, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function moodText(mood as String) as String {
        if (mood.equals("waiting")) {
            return "Needs you";
        }
        if (mood.equals("working")) {
            return "Working";
        }
        if (mood.equals("happy")) {
            return "Done";
        }
        if (mood.equals("idle")) {
            return "All quiet";
        }
        return (Application.getApp() as WristApp).mood;
    }
}
