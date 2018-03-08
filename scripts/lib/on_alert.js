function findAlertTitle(alert) {
    if (!alert) {
        return false;
    }
    var title = alert.name();
    var staticTexts;

    if (title === null) {
        staticTexts = alert.staticTexts();
        if (staticTexts !== null && staticTexts.length > 0) {

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
    ["OK", /[Ww]ould [Ll]ike to [Ss]end [Yy]ou( Push)? Notifications/],
    ["Allow", /Would Like to Add VPN Configurations/]
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
    ["OK", /quiere acceder a tus contactos/],
    ["OK", /quiere acceder a tu calendario/],
    ["OK", /quiere acceder a tus recordatorios/],
    ["OK", /quiere acceder a tus fotos/],
    ["OK", /quiere obtener acceso a cuentas Twitter/],
    ["OK", /quiere acceder al micrófono/],
    ["OK", /desea acceder a tu actividad física y deportiva/],
    ["OK", /quiere acceder a la cámara/],
    ["OK", /quiere enviarte notificaciones/]
  ];
}

function es419SpanishLocalizations() {
  return [
    ["Permitir", /acceda a tu ubicación mientras la app está en uso/],
    ["Permitir", /acceda a tu ubicación incluso cuando la app no está en uso/],
    ["OK", /quiere acceder a tu condición y actividad física/]
  ];
}

function spanishLocalizations() {
  return [].concat(
    euSpanishLocalizations(),
    es419SpanishLocalizations()
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
    ["Sta toe", /tot uw locatie toestaan terwijl u de app gebruikt/],
    ["Sta toe", /toegang tot uw locatie toestaan terwijl u de app gebruikt/],
    ["Sta toe", /ook toegang tot uw locatie toestaan, zelfs als u de app niet gebruikt/],
    ["Sta toe", /toegang tot uw locatie toestaan, zelfs als u de app niet gebruikt/],
    ["OK", /wil toegang tot uw contacten/],
    ["OK", /wil toegang tot uw agenda/],
    ["OK", /wil toegang tot uw herinneringen/],
    ["OK", /wil toegang tot uw foto's/],
    ["OK", /wil toegang tot Twitter-accounts/],
    ["OK", /wil toegang tot de microfoon/],
    ["OK", /wil toegang tot uw bewegings- en fitnessactiviteit/],
    ["OK", /wil toegang tot de camera/],
    ["OK", /wil u berichten sturen/]
  ];
}

function dutch_BE_Localizations() {
  return [
    ["Sta toe", /toegang tot je locatie toestaan terwijl je de app gebruikt/],
    ["Sta toe", /toegang tot je locatie toestaan, zelfs als je de app niet gebruikt/],
    ["OK", /wil toegang tot je contacten/],
    ["OK", /wil toegang tot je agenda/],
    ["OK", /wil toegang tot je herinneringen/],
    ["OK", /wil toegang tot je foto's/],
    ["OK", /wil toegang tot je bewegings- en fitnessactiviteit/]
  ];
}

function swedishLocalizations() {
  return [
    ["Tillåt", /att se din platsinfo när du använder appen/],
    ["Tillåt", /att se din platsinfo även när du inte använder appen/],
    ["Tillåt", /även ser din platsinfo när du inte använder appen/],
    ["OK", /begär åtkomst till dina kontakter/],
    ["OK", /begär åtkomst till din kalender/],
    ["OK", /begär åtkomst till dina påminnelser/],
    ["OK", /begär åtkomst till dina bilder/],
    ["OK", /vill komma åt dina Twitter-konton/],
    ["OK", /begär åtkomst till mikrofonen/],
    ["OK", /begär åtkomst till din rörelse- och träningsaktivitet/],
    ["OK", /begär åtkomst till kameran/],
    ["OK", /vill skicka notiser till dig/]
  ];
}

function russianLocalizations() {
  return [
    ["OK", /запрашивает разрешение на использование Вашей текущей геопозиции/],
    ["OK", /запрашивает разрешение на доступ к учетным записям Twitter/],
    ["Открыть", /Открыть в программе/],
    ["Разрешить", /запрашивает доступ к «Камере»./],
    ["Разрешить", /запрашивает доступ к «Фото»./],
    ["Разрешить", /запрашивает доступ к микрофону./],
    ["Разрешить", /Разрешить доступ к Вашим геоданным/],
    ["Разрешить", /доступ к Вашей геопозиции, даже когда Вы не работаете с этой программой?/],
    ["Разрешить", /доступ к Вашей геопозиции, пока Вы работаете с этой программой?/],
    ["Разрешить", /доступ к Вашей геопозиции, даже когда Вы не работаете с ней?/],
    ["Разрешить", /доступ к Вашей геопозиции, пока Вы работаете с ней?/],
    ["Разрешить", /запрашивает доступ к «Контактам»./],
    ["Разрешить", /запрашивает доступ к «Напоминаниям»./],
    ["Разрешать всегда", /доступ к Вашей геопозиции?/],
    ["Разрешить", /запрашивает доступ к «Календарю»./],
    ["Разрешить", /запрашивает доступ к Вашим данным движения и фитнеса/],
    ["Разрешить", /запрашивает разрешение на отправку Вам уведомлений./]
  ];
}

function frenchLocalizations() {
  return [
    ["OK", /vous envoyer des notifications/],
    ["Autoriser", /à accéder à vos données de localisation lorsque vous utilisez l’app/],
    ["Autoriser", /à accéder à vos données de localisation même lorsque vous n’utilisez pas l’app/],
    ["Autoriser", /à accéder aussi à vos données de localisation lorsque vous n’utilisez pas l’app/],
    ["OK", /souhaite accéder à vos contacts/],
    ["OK", /souhaite accéder à votre calendrier/],
    ["OK", /souhaite accéder à vos rappels/],
    ["OK", /souhaite accéder à vos mouvements et vos activités physiques/],
    ["OK", /souhaite accéder à vos photos/],
    ["OK", /souhaite accéder à l’appareil photo/],
    ["OK", /souhaite accéder aux comptes Twitter/],
    ["OK", /souhaite accéder au micro/]
  ];
}

function portugueseBrazilLocalizations() {
  return [
    ["Permitir", /acesso à sua localização/],
    ["Permitir", /acesso à sua localização/],
    ["OK", /Deseja Ter Acesso às Suas Fotos/],
    ["OK", /Deseja Ter Acesso aos Seus Contatos/],
    ["OK", /Acesso ao Seu Calendário/],
    ["OK", /Deseja Ter Acesso aos Seus Lembretes/],
    ["OK", /Would Like to Access Your Motion Activity/],
    ["OK", /Deseja Ter Acesso à Câmera/],
    ["OK", /Deseja Ter Acesso às Suas Atividades de Movimento e Preparo Físico/],
    ["OK", /Deseja Ter Acesso às Contas do Twitter/],
    ["OK", /data available to nearby bluetooth devices/],
    ["OK", /[Dd]eseja [Ee]nviar-lhe [Nn]otificações/],
    ["Permitir", /Deseja Enviar Notificações/]
  ];
}

function koreanLocalizations() {
  return [
    ["허용", /에서 사용자의 위치에 접근하도록 허용하겠습니까/],
    ["허용", /을(를) 사용하지 않을 때에도 해당 앱이 사용자의 위치에 접근하도록 허용하곘습니까/],
    ["승인", /이(가) 사용자의 연락처에 접근하려고 합니다/],
    ["승인", /이(가) 사용자의 캘린더에 접근하려고 합니다/],
    ["승인", /이(가) 사용자의 미리 알림에 접근하려고 합니다/],
    ["승인", /이(가) 사용자의 사진에 접근하려고 합니다/],
    ["승인", /이(가) 카메라에 접근하려고 합니다/],
    ["승인", /에서 Twitter 계정에 접근하려고 합니다/],
    ["승인", /이(가) 사용자의 동작 및 피트니스 활동에 접근하려고 합니다/],
    ["승인", "이(가) 마이크에 접근하려고 합니다"],
    ["허용", "에서 알림을 보내고자 합니다"]
  ];
}

function localizations() {
  return [].concat(
     danishLocalizations(),
     dutchLocalizations(),
     dutch_BE_Localizations(),
     swedishLocalizations(),
     englishLocalizations(),
     germanLocalizations(),
     russianLocalizations(),
     spanishLocalizations(),
     frenchLocalizations(),
     portugueseBrazilLocalizations(),
     koreanLocalizations()
  );
}

function isPrivacyAlert(alert) {

  var expressions = localizations();

  var title = findAlertTitle(alert);

  // Comment this out when capturing new regexes. See the comment below.
  Log.output({"alert":title});

  // When debugging or trying to capture the regexes for a new
  // localization, uncomment the logging below.
  //
  // Notes:
  // * Microphone alerts only appear on physical devices.
  // * You have to click through the Health alert; it is completely blocking -
  //   tests will not proceed.
  // * Generating bluetooth alerts is NYI.
  // * In general, there will be a different alert on device for using location
  //   in background mode.
  // * Alerts vary by iOS.
  // * To reset notifications on devices:
  //   General > Settings > Reset > Reset Location + Privacy
  //   - These are the last table rows
  //   - APNS permissions are reset once a day.
  // * On devices, set the device language in Settings.
  //
  // Use the Permission.app.
  //
  // * Alert text is printed at the end of every test.
  // * Alert text is written to a file in Permissions/tmp.
  //
  // Examples:
  //
  // # Simulator running Mexican Spanish
  // $ APP_LANG="es-MX" APP_LOCALE="es_MX" be cucumber -t @supported
  //
  // # Device running Dutch
  // $ APP_LANG="nl" APP_LOCALE="nl" be cucumber -t @supported -p macmini

  // This is very slow, so only do this if you are trying to capture regexes.
  // var buttonNames = findAlertButtonNames(alert);
  // Log.output({"alert":{"title":title, "buttons":buttonNames, "capture":"YES"}});

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
