var target = UIATarget.localTarget(),
    screenshot_count = 0;

function findAlertViewText(alert) {
    if (!alert) {
        return false;
    }
    var txt = alert.name(),
        txts;
    if (txt == null) {
        txts = alert.staticTexts();
        if (txts != null && txts.length > 0) {

            txt = txts[0].name();
        }

    }
    return txt;
}

function isLocationPrompt(alert) {
    var exps = [
            ["OK", /vil bruge din aktuelle placering/],
            ["OK", /Would Like to Use Your Current Location/],
            ["Ja", /Darf (?:.)+ Ihren aktuellen Ort verwenden/]
        ],
        ans, exp,
        txt;

    txt = findAlertViewText(alert);
    for (var i = 0; i < exps.length; i++) {
        ans = exps[i][0];
        exp = exps[i][1];
        if (exp.test(txt)) {
            return ans;
        }
    }
    return false;
}


var alertHandlers = [//run in reverse order of this:
    isLocationPrompt
];


UIATarget.onAlert = function (alert) {
    var N = alertHandlers.length;
    while (N--) {
        if (alertHandlers[i]) {
            break;
        }
    }
    return true;
};

function performAction(action, data) {
    UIALogger.logMessage("perform action:" + action);
    var actionTaken = true,
        res = null;
    switch (action) {
        case "setLocation":
            target.setLocation({"latitude":data.latitude, "longitude":data.longitude});
            break;
        case "background":
            target.deactivateAppForDuration(data.duration);
            break;
        case "registerAlertHandler":
            alertHandlers.push(eval(data.handler));
            break;
        case "screenshot":
            screenshot_count += 1;
            target.captureScreenWithName(data.name || ("screenshot_" + screenshot_count));
            break;
        case "eval":
            try {
                res = eval(data);
            } catch (e) {
                if (e) {
                    UIALogger.logMessage(e.toString());
                }
            }
            break;
    }
    if (actionTaken && !data.preserve) {
        target.frontMostApp().setPreferencesValueForKey(null, "__run_loop_action");
    }
    return res;

}

UIALogger.logStart("RunLoop");

var app = target.frontMostApp(),
    val,
    res,
    count = 0,
    action = null;
while (true) {
    target.delay(1);
    val = target.frontMostApp().preferencesValueForKey("__run_loop_action");
    if (val)
        UIALogger.logMessage(val);
    else {
        UIALogger.logMessage("null");
        val = target.frontMostApp().preferencesValueForKey("x");
        if (val)
            UIALogger.logMessage(val.toString());
    }

    if (val && typeof val == 'object') {
        action = val.action;
        performAction(action, val);
    }
    else if (val && typeof val == 'string') {
        res = performAction("eval", val);
        if (res) {
            UIALogger.logMessage(res.toString());
        }
    }

    count += 1;
}

UIALogger.logPass("RunLoop");