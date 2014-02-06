#import "calabash_script_uia.js"

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


var _expectedIndex = 0,//expected index of next command
    _actualIndex=0,//actual index of next command by reading commandPath
    _exp,//expression to be eval'ed
    _result;

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
            ["OK", /Would Like to Access Your Photos/]
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
    Log.output({"output":"on alert"}, true);
    var target = UIATarget.localTarget();
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

/*
 (defn sanitize
 "Removes elements not serializable to preferences"
 [x]

 (cond
 (nil? x) ":nil"
 (string? x) x
 (keyword? x) (name x)
 (map? x) (into {}
 (map (fn [[k v]]
 [k (sanitize v)])
 x))
 (coll? x) (map sanitize x)
 (instance? js/UIAElement x) (.toString x)
 :else x))

 */

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
            MAX_TRIES=30,
            res;
        target.frontMostApp().setPreferencesValueForKey(sanitized, __calabashResponse);

        for (i=0; i<MAX_TRIES; i+=1) {
            res = target.frontMostApp().preferencesValueForKey(__calabashResponse);
            if (res && res['index'] == sanitized['index']) {
                return;
            }
        }
        throw new Error("Unable to write to preferences");

    },
    _success = function(result,index) {

        _response({"status":'success', "value":result, "index": index});

    },
    _failure = function(err, index) {
        _response({"status":'error',
                   "value":err.toString(),
                   "backtrace":(err.stack ? err.stack.toString() : ""),
                   "index":index});
    };

UIATarget.localTarget().frontMostApp().setPreferencesValueForKey(null, __calabashResponse);
UIATarget.localTarget().frontMostApp().setPreferencesValueForKey(0, __calabashRequest);

Log.result('success',true,true);
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
        _exp = preferences['command'];
        UIALogger.logMessage("index " + _actualIndex + " is command: "+ _exp);
        target.frontMostApp().setPreferencesValueForKey(null, __calabashRequest);
        try {
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
    _expectedIndex++;


    target.delay(0.2);
}
