function findAlertTitle(alert) {
    if (!alert) {
        return false;
    }
    var title = alert.name();
    var staticTexts;

    if (title == null) {
        staticTexts = alert.staticTexts();
        if (staticTexts != null && staticTexts.length > 0) {

            title = staticText[0].name();
        }

    }
    return title;
}

function findAlertButtonNames(alert) {
  if (!alert) {
    return false;
  }

  var buttons = alert.buttons();
  var leftButton = buttons[0].name();
  var rightButton = buttons[1].name();

  return leftButton + "," + rightButton;
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
    ["OK", /[Ww]ould [Ll]ike to [Ss]end [Yy]ou( Push)? Notifications/]
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

function frenchLocalizations() {
  return [
    ["OK", /vous envoyer des notifications/],
    ["Autoriser", /à accéder à vos données de localisation lorsque vous utilisez l’app/],
    ["Autoriser", /à accéder à vos données de localisation même lorsque vous n’utilisez pas l’app/],
    ["OK", /souhaite accéder à vos contacts/],
    ["OK", /souhaite accéder à votre calendrier/],
    ["OK", /souhaite accéder à vos rappels/],
    ["OK", /souhaite accéder à vos mouvements et vos activités physiques/],
    ["OK", /souhaite accéder à vos photos/],
    ["OK", /souhaite accéder à l’appareil photo/],
    ["OK", /souhaite accéder aux comptes Twitter/]
  ];
}

function localizations() {
  return [].concat(
     danishLocalizations(),
     dutchLocalizations(),
     englishLocalizations(),
     germanLocalizations(),
     russianLocalizations(),
     spanishLocalizations(),
     frenchLocalizations()
  );
}

function isPrivacyAlert(alert) {

  var expressions = localizations();

  var title = findAlertTitle(alert);

  // When debugging or trying to capture the regexes for a new
  // localization, uncomment these lines.
  // var buttonNames = findAlertButtonNames(alert);
  // Log.output({"output":"alert: " + title + "," + buttonNames}, true);

  var answer;
  var expression;
  for (var i = 0; i < expressions.length; i++) {
    answer = expressions[i][0];
    expression = expressions[i][1];
    if (expression.test(title)) {
      return answer;
    }
  }
  return false;
}

