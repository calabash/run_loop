<%= render_template("lib/json2.min.js") %>

_RUN_LOOP_MAX_RETRY_AFTER_HANDLER = 10;
var _expectedIndex = 0,//expected index of next command
    _actualIndex=0,//actual index of next command by reading commandPath
    _exp,//expression to be eval'ed
    _result,
    _lastResponse=null;

<%= render_template("lib/log.js"); %>
<%= render_template("lib/on_alert.js"); %>

UIATarget.onAlert = function (alert) {
    var target = UIATarget.localTarget(),
        app = target.frontMostApp(),
        req = null,
        rsp = null,
        actualIndex = null;
    target.pushTimeout(10);
    function dismissPrivacyAlert(retry_count) {
        retry_count = retry_count || 0;
        if (retry_count >= 5) {
            Log.output("Maxed out retry (5) - unable to dismiss privacy dialog.");
            return;
        }
        try {
            var answer = isPrivacyAlert(alert);
            if (answer) {
                alert.buttons()[answer].tap();
            }
        }
        catch (e) {
            Log.output("Exception while trying to touch alert. Retrying...");
            if (e && typeof e.toString == 'function') {
                Log.output(e.toString());
            }
            target.delay(1);
            dismissPrivacyAlert(retry_count + 1);
        }
    }

    dismissPrivacyAlert(0);
    target.popTimeout();
    return true;
};


Log.result('success', true);

var _calabashSharedTextField = null,
    __calabashSharedTextFieldName = '__calabash_uia_channel',
    _firstElement,
    target = null,
    failureMessage = null,
    _request = null,
    _response = function(response) {
        response.type = 'response';
        var jsonResponse = JSON.stringify(response);
        UIALogger.logMessage("Response: "+ jsonResponse);
        _calabashSharedTextField.setValue(jsonResponse);
    },
    _success = function(result,index) {
        _lastResponse = {"status":'success', "value":result, "index": index};
        _response(_lastResponse);
    },
    _failure = function(err, index) {
        _lastResponse = {"status":'error',
            "value":err.toString(),
            "backtrace":(err.stack ? err.stack.toString() : ""),
            "index":index};
        _response(_lastResponse);
    },
    _syncDoneJSON='{"type":"syncDone"}';

UIALogger.logMessage("Waiting for shared element...");
target = UIATarget.localTarget();
while (!_calabashSharedTextField) {
    _firstElement = target.frontMostApp().mainWindow().elements()[0];
    if (_firstElement instanceof UIATextField) {
        if (_firstElement.name() == __calabashSharedTextFieldName) {
          _calabashSharedTextField = _firstElement;
          UIALogger.logMessage("Found shared element... Responding: syncDone");
          _calabashSharedTextField.setValue(_syncDoneJSON);
          target.delay(0.5);
          break;
        }
    }
    target.delay(0.3);
}

while (true) {
    _request = _calabashSharedTextField.value();

    if (!_request || _request === _syncDoneJSON) {
        target.delay(0.2);
        continue;
    }

    UIALogger.logMessage("index " + _actualIndex + " is request: "+ _request);
    _request = JSON.parse(_request);

    _actualIndex = _request['index'];
    if (!isNaN(_actualIndex) && _actualIndex >= _expectedIndex) {
        _exp = _request['command'];
        UIALogger.logMessage("index " + _actualIndex + " is command: "+ _exp);
        try {
            if (_exp == 'break;') {
                _success("OK", _actualIndex);
                break;
            }
            _result = eval(_exp);
            UIALogger.logMessage("Success: "+ _result);
            _success(_result, _actualIndex);
        }
        catch(err) {
            failureMessage = "Failure: "+ err.toString() + "  " + (err.stack ? err.stack.toString() : "");
            Log.output({"output":failureMessage});
            _failure(err, _actualIndex);
        }
    }
    else {//likely old command is lingering...
        continue;
    }
    _expectedIndex = Math.max(_actualIndex+1, _expectedIndex+1);
}
