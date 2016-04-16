<% render_template("lib/json2.min.js") %>

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
            Log.output("Maxed out retry (5) - unable to dismiss privacy alert.");
            return;
        }
        try {
            var answer = isPrivacyAlert(alert);
            if (answer) {
                alert.buttons()[answer].tap();
            }
        }
        catch (e) {
            Log.output("Exception while trying to touch privacy alert. Retrying...");
            if (e && typeof e.toString == 'function') {
                Log.output(e.toString());
            }
            target.delay(1);
            dismissPrivacyAlert(retry_count + 1);
        }
    }

    dismissPrivacyAlert(0);
    target.popTimeout();

    for (var i=0;i<_RUN_LOOP_MAX_RETRY_AFTER_HANDLER;i++) {
        req = app.preferencesValueForKey(__calabashRequest);
        rsp = app.preferencesValueForKey(__calabashResponse);
        actualIndex = req && req['index'];
        if (req && !isNaN(actualIndex) && actualIndex <= _lastResponse['index']) {
            UIALogger.logMessage("Deleting previous response: "+(rsp && rsp['index']));
            app.setPreferencesValueForKey(0, __calabashRequest);
            app.setPreferencesValueForKey(null, __calabashRequest);
        }
        if (_lastResponse) {
            UIALogger.logMessage("Re-Writing response: "+_lastResponse['value']);
            _response(_lastResponse);
        }
    }
    return true;
};

var target = null,
    failureMessage = null,
    preferences = null,
    __calabashRequest = "__calabashRequest",
    __calabashResponse = "__calabashResponse",
    _sanitize = function(val) {
        if (typeof val === 'undefined' || val === null || val instanceof UIAElementNil) {
            return ":nil";
        }
        if (typeof val === 'string' || val instanceof String) {
            return val;
        }
        var arrVal = null, i, N;
        if (val instanceof Array || val instanceof UIAElementArray) {
            arrVal = [];
            for (i=0,N=val.length;i<N;i++) {
                arrVal[i] = _sanitize(val[i]);
            }
            return arrVal;
        }
        if (val instanceof UIAElement) {
            return val.toString();
        }
        var objVal = null, p;
        if (typeof val == 'object') {
            objVal = {};
            for (p in val) {
                objVal[p] = _sanitize(val[p]);
            }
            return objVal;
        }
        return val;
    },
    _response = function(response) {
        var sanitized = _sanitize(response),
            i = 0,
            MAX_TRIES=120,
            res,
            tmp;

        for (i=0; i<MAX_TRIES; i+=1) {
            tmp = target.frontMostApp().preferencesValueForKey(__calabashResponse);
            UIALogger.logMessage("Last response..."+(tmp && tmp['index']+"->"+tmp['value']));
            target.frontMostApp().setPreferencesValueForKey(sanitized, __calabashResponse);
            res = target.frontMostApp().preferencesValueForKey(__calabashRequest);
            res = target.frontMostApp().preferencesValueForKey(__calabashResponse);
            UIALogger.logMessage("Next response..."+(res && res['value']));
            target.delay(0.1);
            res = target.frontMostApp().preferencesValueForKey(__calabashResponse);
            UIALogger.logMessage("Post delay response..."+(res && res['value']));
            if (res && res['index'] == sanitized['index']) {
                UIALogger.logMessage("Storage succeeded: "+ res['index']);
                return;
            } else {
                UIALogger.logMessage("Storage failed: "+ res + " Retrying...");
                target.delay(0.2);
            }
        }
        throw new Error("Unable to write to preferences");
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
    _resetCalabashPreferences = function () {
        //Implementation is weird but reading pref values seems to have side effects
        //also deleting a key seemed to require writing 0 and then null :)
        var app = UIATarget.localTarget().frontMostApp();
        app.preferencesValueForKey(__calabashRequest);
        app.preferencesValueForKey(__calabashResponse);
        app.setPreferencesValueForKey(0, __calabashResponse);
        app.setPreferencesValueForKey(null, __calabashResponse);
        app.setPreferencesValueForKey(0, __calabashRequest);
        app.setPreferencesValueForKey(null, __calabashRequest);
    };

_resetCalabashPreferences();
Log.result('success', true);
target = UIATarget.localTarget();
while (true) {
    try {
        preferences = target.frontMostApp().preferencesValueForKey(__calabashRequest);
    } catch (e) {
        Log.output("Unable to read preferences..."+ e.toString());
        target.delay(0.5);
        continue;
    }

    if (!preferences) {
        target.delay(0.2);
        continue;
    }

    _actualIndex = preferences['index'];
    if (!isNaN(_actualIndex) && _actualIndex >= _expectedIndex) {
        UIATarget.localTarget().frontMostApp().setPreferencesValueForKey(null, __calabashResponse);
        _exp = preferences['command'];
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
    target.delay(0.2);
}
