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
    ["Tillad", /bruge din lokalitet, når du bruger appen/],
    ["Tillad", /også når du ikke bruger appen/],
    ["OK", /vil bruge din aktuelle placering/],
    ["OK", /vil bruge dine kontakter/],
    ["OK", /vil bruge mikrofonen/],
    ["OK", /vil bruge din kalender/],
    ["OK", /vil bruge dine påmindelser/],
    ["OK", /vil bruge dine fotos/],
    ["OK", /ønsker adgang til Twitter-konti/],
    ["OK", /vil bruge din fysiske aktivitet og din træningsaktivitet/],
    ["OK", /vil bruge kameraet/],
    ["OK", /vil gerne sende dig meddelelser/]
  ];
}

function euSpanishLocalizations() {
  return [
    ["Permitir", /acceder a tu ubicación mientras utilizas la aplicación/],
    ["Permitir", /acceder a tu ubicación aunque no estés utilizando la aplicación/],
    ["OK", /acceder a tu ubicación mientras utilizas la aplicación/],
    ["OK", /acceder a tu ubicación aunque no estés utilizando la aplicación/],
    ["OK", /quiere acceder a tus contactos/],
    ["OK", /quiere acceder a tu calendario/],
    ["OK", /quiere acceder a tus recordatorios/],
    ["OK", /quiere acceder a tus fotos/],
    ["OK", /quiere obtener acceso a cuentas Twitter/],
    ["OK", /desea acceder a tu actividad física y deportiva/],
    ["OK", /quiere acceder a la cámara/],
    ["OK", /quiere enviarte notificaciones/]
    // Possibly a typo.
    ["OK", /enviarle notificaiones/]
  ];
}

function es419SpanishLocalizations() {
  return [
    // Same as EU Spanish
  ];
}

function usSpanishLocalizations() {
  return [
    // Same as EU Spanish
  ];
}

function spanishLocalizations() {
  return [].concat(
    euSpanishLocalizations(),
    es419SpanishLocalizations(),
    usSpanishLocalizations()
  );
}

function germanLocalizations() {
  return [
    ["Ja", /Darf (?:.)+ Ihren aktuellen Ort verwenden/],
    ["Erlauben", /auf Ihren Standort zugreifen, wenn Sie die App benutzen/],
    ["Erlauben", /auch auf Ihren Standort zugreifen, wenn Sie die App nicht benutzen/],
    ["Erlauben", /auf Ihren Standort zugreifen, selbst wenn Sie die App nicht benutzen/],
    ["Ja", /auf Ihre Kontakte zugreifen/],
    ["Ja", /auf Ihren Kalender zugreifen/],
    ["Ja", /auf Ihre Erinnerungen zugreifen/],
    ["Ja", /auf Ihre Fotos zugreifen/],
    ["Erlauben", /möchte auf Twitter-Accounts zugreifen/],
    ["Ja", /auf das Mikrofon zugreifen/],
    ["Ja", /möchte auf Ihre Bewegungs- und Fitnessdaten zugreifen/],
    ["Ja", /auf Ihre Kamera zugreifen/],
    ["OK", /Ihnen Mitteilungen senden/]
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

  // Comment this out if you are capturing regexes.  See comment below.
  Log.output({"output":"alert: " + title}, true);

  // When debugging or trying to capture the regexes for a new
  // localization, uncomment these lines and comment out the line above.
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

