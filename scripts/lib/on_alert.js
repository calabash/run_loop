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

function englishLocalizations() {
  return [
    ["OK", /Would Like to Use Your Current Location/],
    ["OK", /Location Accuracy/],
    ["Allow", /access your location/],
    ["OK", /Would Like to Access Your Photos/],
    ["OK", /Would Like to Access Your Contacts/],
    ["OK", /Access the Microphone/],
    ["OK", /Would Like to Access Your Calendar/],
    ["OK", /Would Like to Access Your Reminders/],
    ["OK", /Would Like to Access Your Motion Activity/],
    ["OK", /Would Like to Access the Camera/],
    ["OK", /Would Like to Access Your Motion & Fitness Activity/],
    ["OK", /Would Like Access to Twitter Accounts/],
    ["OK", /data available to nearby bluetooth devices/],
    ["OK", /Would Like to Send You Notifications/],
    ["OK", /would like to send you Push Notifications/]
  ];
}

function danishLocalizations() {
  return [
    // Location
    ["Tillad", /bruge din lokalitet, når du bruger appen/],
    ["Tillad", /også når du ikke bruger appen/],
    ["OK", /vil bruge din aktuelle placering/]
  ];
}

function spanishLocalizations() {
  return [
    // APNS
    ["OK", /enviarle notificaiones/]
  ];
}

function germanLocalizations() {
  return [
    // Location
    ["Ja", /Darf (?:.)+ Ihren aktuellen Ort verwenden/]
  ];
}

function dutchLocalizations() {
  return [
    // APNS
    ["OK", /wil u berichten stuern/]
  ];
}

function russianLocalizations() {
  return [
    // Location
    ["OK", /запрашивает разрешение на использование Ващей текущей пгеопозиции/]
  ];
}

function localizations() {
  return [].concat(
     danishLocalizations(),
     dutchLocalizations(),
     englishLocalizations(),
     germanLocalizations(),
     russianLocalizations(),
     spanishLocalizations()
  );
}

function isPrivacyAlert(alert) {

  var ans, exp, txt;

  var exps = localizations();

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

