var target = UIATarget.localTarget();

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


UIATarget.onAlert = function (alert)
{
    var N = alertHandlers.length;
    while(N--)
    {
        if (alertHandlers[i])
        {
            break;
        }
    }
    return true;
};

function performAction(action, data) {
    UIALogger.logMessage("perform action:" + action);
    var actionTaken = true;
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
    }
    if (actionTaken && !data.preserve) {
        target.frontMostApp().setPreferencesValueForKey(null, "__run_loop_action");
    }

}

UIALogger.logStart("RunLoop");

var app = target.frontMostApp()
    val,
    count = 0,
    shouldAccept = true,
    alertAction = null,
    action = null;
while (true) {
    target.delay(0.3);
    val = app.preferencesValueForKey("__run_loop_action");
    if (val && typeof val == 'object') {
        action = val.action;
        if (action == "allowLocation") {
            shouldAccept = !!val.data;
        }
        else {
            performAction(action, val);
        }
    }
    UIALogger.logPass("Test" + count);
    count += 1;
}

UIALogger.logPass("RunLoop");