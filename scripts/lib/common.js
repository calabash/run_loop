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
            ["Ja", /Darf (?:.)+ Ihren aktuellen Ort verwenden/],
            ["OK", /Would Like to Send You Notifications/],
            ["OK", /would like to send you Push Notifications/],
            ["Allow", /access your location/],
            ["OK", /Would Like to Access Your Photos/],
            ["OK", /Would Like to Access Your Contacts/],
            ["OK", /Location Accuracy/],
            ["OK", /запрашивает разрешение на использование Ващей текущей пгеопозиции/],
            ["OK", /Access the Microphone/],
            ["OK", /enviarle notificaiones/],
            ["OK", /Would Like to Access Your Calendar/],
            ["OK", /Would Like to Access Your Reminders/],
            ["OK", /Would Like to Access Your Motion Activity/],
            ["OK", /Would Like to Access the Camera/],

            //iOS 9 - English
            ["OK", /Would Like to Access Your Motion & Fitness Activity/],
            ["OK", /Would Like Access to Twitter Accounts/]
        ],
        ans, exp,
        txt;

    txt = findAlertViewText(alert);
    Log.output({"output":"alert: "+txt}, true);
    for (var i = 0; i < exps.length; i++) {
        ans = exps[i][0];
        exp = exps[i][1];
        if (exp.test(txt)) {
            return ans;
        }
    }
    return false;
}
