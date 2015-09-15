if (typeof JSON !== 'object') {
    JSON = {};
}
(function () {
    'use strict';
    function f(n) {
        return n < 10 ? '0' + n : n;
    }

    if (typeof Date.prototype.toJSON !== 'function') {
        Date.prototype.toJSON = function (key) {
            return isFinite(this.valueOf()) ? this.getUTCFullYear() + '-' +
                f(this.getUTCMonth() + 1) + '-' +
                f(this.getUTCDate()) + 'T' +
                f(this.getUTCHours()) + ':' +
                f(this.getUTCMinutes()) + ':' +
                f(this.getUTCSeconds()) + 'Z' : null;
        };
        String.prototype.toJSON = Number.prototype.toJSON = Boolean.prototype.toJSON = function (key) {
            return this.valueOf();
        };
    }
    var cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g, escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g, gap, indent, meta = {'\b': '\\b', '\t': '\\t', '\n': '\\n', '\f': '\\f', '\r': '\\r', '"': '\\"', '\\': '\\\\'}, rep;

    function quote(string) {
        escapable.lastIndex = 0;
        return escapable.test(string) ? '"' + string.replace(escapable, function (a) {
            var c = meta[a];
            return typeof c === 'string' ? c : '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
        }) + '"' : '"' + string + '"';
    }

    function str(key, holder) {
        var i, k, v, length, mind = gap, partial, value = holder[key];
        if (value && typeof value === 'object' && typeof value.toJSON === 'function') {
            value = value.toJSON(key);
        }
        if (typeof rep === 'function') {
            value = rep.call(holder, key, value);
        }
        switch (typeof value) {
            case'string':
                return quote(value);
            case'number':
                return isFinite(value) ? String(value) : 'null';
            case'boolean':
            case'null':
                return String(value);
            case'object':
                if (!value) {
                    return'null';
                }
                gap += indent;
                partial = [];
                if (Object.prototype.toString.apply(value) === '[object Array]') {
                    length = value.length;
                    for (i = 0; i < length; i += 1) {
                        partial[i] = str(i, value) || 'null';
                    }
                    v = partial.length === 0 ? '[]' : gap ? '[\n' + gap + partial.join(',\n' + gap) + '\n' + mind + ']' : '[' + partial.join(',') + ']';
                    gap = mind;
                    return v;
                }
                if (rep && typeof rep === 'object') {
                    length = rep.length;
                    for (i = 0; i < length; i += 1) {
                        if (typeof rep[i] === 'string') {
                            k = rep[i];
                            v = str(k, value);
                            if (v) {
                                partial.push(quote(k) + (gap ? ': ' : ':') + v);
                            }
                        }
                    }
                } else {
                    for (k in value) {
                        if (Object.prototype.hasOwnProperty.call(value, k)) {
                            v = str(k, value);
                            if (v) {
                                partial.push(quote(k) + (gap ? ': ' : ':') + v);
                            }
                        }
                    }
                }
                v = partial.length === 0 ? '{}' : gap ? '{\n' + gap + partial.join(',\n' + gap) + '\n' + mind + '}' : '{' + partial.join(',') + '}';
                gap = mind;
                return v;
        }
    }

    if (typeof JSON.stringify !== 'function') {
        JSON.stringify = function (value, replacer, space) {
            var i;
            gap = '';
            indent = '';
            if (typeof space === 'number') {
                for (i = 0; i < space; i += 1) {
                    indent += ' ';
                }
            } else if (typeof space === 'string') {
                indent = space;
            }
            rep = replacer;
            if (replacer && typeof replacer !== 'function' && (typeof replacer !== 'object' || typeof replacer.length !== 'number')) {
                throw new Error('JSON.stringify');
            }
            return str('', {'': value});
        };
    }
    if (typeof JSON.parse !== 'function') {
        JSON.parse = function (text, reviver) {
            var j;

            function walk(holder, key) {
                var k, v, value = holder[key];
                if (value && typeof value === 'object') {
                    for (k in value) {
                        if (Object.prototype.hasOwnProperty.call(value, k)) {
                            v = walk(value, k);
                            if (v !== undefined) {
                                value[k] = v;
                            } else {
                                delete value[k];
                            }
                        }
                    }
                }
                return reviver.call(holder, key, value);
            }

            text = String(text);
            cx.lastIndex = 0;
            if (cx.test(text)) {
                text = text.replace(cx, function (a) {
                    return'\\u' +
                        ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
                });
            }
            if (/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                j = eval('(' + text + ')');
                return typeof reviver === 'function' ? walk({'': j}, '') : j;
            }
            throw new SyntaxError('JSON.parse');
        };
    }
}());


_RUN_LOOP_MAX_RETRY_AFTER_HANDLER = 10;
var _expectedIndex = 0,//expected index of next command
    _actualIndex=0,//actual index of next command by reading commandPath
    _exp,//expression to be eval'ed
    _result,
    _lastResponse=null;

var Log = (function () {
    var forceFlush = [],
        N = 16384,
        i = N;
    while (i--) {
        forceFlush[i] = "*";
    }
    forceFlush = forceFlush.join('');

    function log_json(object, flush)
    {
        UIALogger.logMessage("OUTPUT_JSON:\n"+JSON.stringify(object)+"\nEND_OUTPUT");
        if (flush) {
            UIALogger.logMessage(forceFlush);
        }
    }

    return {
        result: function (status, data, flush) {
            log_json({"status": status, "value": data, "index":_actualIndex}, flush)
        },
        output: function (msg, flush) {
            log_json({"output": msg,"last_index":_actualIndex}, flush);
        }
    };
})();


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

UIATarget.onAlert = function (alert) {
    var target = UIATarget.localTarget(),
        app = target.frontMostApp(),
        req = null,
        rsp = null,
        actualIndex = null;
    target.pushTimeout(10);
    function attemptTouchOKOnLocation(retry_count) {
        retry_count = retry_count || 0;
        if (retry_count >= 5) {
            Log.output("Maxed out retry (5) - unable to dismiss location dialog.");
            return;
        }
        try {
            var answer = isLocationPrompt(alert);
            if (answer) {
                alert.buttons()[answer].tap();
            }
        }
        catch (e) {
            Log.output("Exception while trying to touch alert dialog. Retrying...");
            if (e && typeof e.toString == 'function') {
                Log.output(e.toString());
            }
            target.delay(1);
            attemptTouchOKOnLocation(retry_count + 1);
        }
    }

    attemptTouchOKOnLocation(0);
    target.popTimeout();
    return true;
};


Log.result('success',true,true);

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
            Log.output({"output":failureMessage}, true);
            _failure(err, _actualIndex);
        }
    }
    else {//likely old command is lingering...
        continue;
    }
    _expectedIndex = Math.max(_actualIndex+1, _expectedIndex+1);
}
