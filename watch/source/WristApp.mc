import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Asks the listener for the state every 10 seconds and sends commands to it.
class WristApp extends Application.AppBase {
    var mood as String = "...";
    var tail as Array = [];
    hidden var _timer as Timer.Timer?;
    hidden var _happyUntil as Number = 0;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        var t = new Timer.Timer();
        t.start(method(:poll), 10000, true);
        _timer = t;
        poll();
    }

    function onStop(state as Dictionary?) as Void {
        if (_timer != null) {
            _timer.stop();
        }
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new WristView(), new WristDelegate()];
    }

    function onSettingsChanged() as Void {
        poll();
    }

    function poll() as Void {
        Communications.makeWebRequest(setting("serverUrl") + "/wrist/state", null,
            options(Communications.HTTP_REQUEST_METHOD_GET), method(:onState));
    }

    function send(body as Dictionary) as Void {
        Communications.makeWebRequest(setting("serverUrl") + "/wrist/command", body,
            options(Communications.HTTP_REQUEST_METHOD_POST), method(:onSent));
    }

    function onState(code as Number, data as Dictionary or String or Null) as Void {
        if (code == 200 && data instanceof Dictionary) {
            var next = data["mood"] as String;
            // A turn that ends shows Clawd happy for 5 seconds.
            if (mood.equals("working") && next.equals("idle")) {
                _happyUntil = System.getTimer() + 5000;
            }
            mood = next;
            tail = data["tail"] as Array;
        } else {
            mood = "error " + code;
            tail = [];
        }
        WatchUi.requestUpdate();
    }

    function onSent(code as Number, data as Dictionary or String or Null) as Void {
        poll();
    }

    // The mood Clawd acts out: the listener's mood, "happy" just after a turn
    // ends, and asleep (any other word) while the listener cannot be reached.
    function faceMood() as String {
        if (mood.equals("idle") && System.getTimer() < _happyUntil) {
            return "happy";
        }
        return mood;
    }

    function setting(id as String) as String {
        var v = Application.Properties.getValue(id);
        return v == null ? "" : v as String;
    }

    hidden function options(verb as Communications.HttpRequestMethod) as Dictionary {
        return {
            :method => verb,
            :headers => {
                "Authorization" => "Bearer " + setting("watchKey"),
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
    }
}
