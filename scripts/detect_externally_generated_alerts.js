#import "./logger.js";

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

function isExternallyGeneratedAlert(alert) {
  var exps =
              [
                // Location Alerts
                ["OK", /vil bruge din aktuelle placering/],
                ["OK", /Would Like to Use Your Current Location/],
                ["Allow", /access your location/],
                ["Ja", /Darf (?:.)+ Ihren aktuellen Ort verwenden/],
                ["OK", /Location Accuracy/],
                ["OK", /запрашивает разрешение на использование Ващей текущей пгеопозиции/],

                // Notifications
                ["OK", /Would Like to Send You Notifications/],

                // Photos
                ["OK", /Would Like to Access Your Photos/],

                // Contacts
                ["OK", /Would Like to Access Your Contacts/]
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
