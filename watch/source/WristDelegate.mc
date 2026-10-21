import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// START opens the command menu: Enter, Esc, and the quick phrases.
class WristDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        var app = Application.getApp() as WristApp;
        var menu = new WatchUi.Menu2({:title => "Agent"});
        menu.addItem(new WatchUi.MenuItem("Enter", null, "enter", null));
        menu.addItem(new WatchUi.MenuItem("Esc", null, "esc", null));
        var ids = ["phrase1", "phrase2", "phrase3"];
        for (var i = 0; i < ids.size(); i++) {
            var text = app.setting(ids[i]);
            if (text.length() > 0) {
                menu.addItem(new WatchUi.MenuItem(text, null, ids[i], null));
            }
        }
        WatchUi.pushView(menu, new CommandDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}

class CommandDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var app = Application.getApp() as WristApp;
        var id = item.getId() as String;
        if (id.equals("enter") || id.equals("esc")) {
            app.send({"command" => id});
        } else {
            app.send({"command" => "say", "text" => app.setting(id)});
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
