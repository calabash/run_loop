//#import "calabash_script_uia.js"

<%= render_template("lib/json2.min.js") %>

var commandPath = "$PATH";
if (!/\/$/.test(commandPath)) {
    commandPath += "/";
}
commandPath += "repl-cmd.pipe";

var timeoutScriptPath = "$TIMEOUT_SCRIPT_PATH",
    readPipeScriptPath = "$READ_SCRIPT_PATH";

var _expectedIndex = 0,//expected index of next command
    _actualIndex,//actual index of next command by reading commandPath
    _index,//index of ':' char in command
    _exp = null,//expression to be eval'ed
    _result,//result of eval
    _input,//command
    _process;//host command process

<%= render_template("lib/log.js"); %>
<%= render_template("lib/on_alert.js"); %>

UIATarget.onAlert = function (alert) {
    Log.output({"output":"on alert"});
    var target = UIATarget.localTarget();
    target.pushTimeout(10);
    function dismissPrivacyAlert(retry_count) {
        retry_count = retry_count || 0;
        if (retry_count >= 5) {
            Log.output("Maxed out retry (5) - unable to dismiss location dialog.");
            return;
        }
        try {
            var answer = isPrivacyAlert(alert);
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
            dismissPrivacyAlert(retry_count + 1);
        }
    }

    dismissPrivacyAlert(0);
    target.popTimeout();
    return true;
};


var target = null,
    host = null;


Log.output('Starting loop');
while (true) {
    target = UIATarget.localTarget();

    host = target.host();
    try {
        _process = host.performTaskWithPathArgumentsTimeout(timeoutScriptPath,
            [readPipeScriptPath, commandPath],
           10);

    } catch (e) {
        Log.output("Timeout on read command..." + e);
        continue;
    }
    if (_process.exitCode != 0) {
        if (_process.exitCode != 15) {
            Log.output("unable to execute: " +
                  timeoutScriptPath + " " +
                  readPipeScriptPath + " " +
                  commandPath + " exitCode "
                  + _process.exitCode + ". Error: " +
                  _process.stderr + _process.stdout);
        }
    }
    else {
        _input = _process.stdout;
        try {
            _index = _input.indexOf(":", 0);
            if (_index > -1) {
                _actualIndex = parseInt(_input.substring(0, _index), 10);
                if (!isNaN(_actualIndex) && _actualIndex >= _expectedIndex) {
                    _exp = _input.substring(_index + 1, _input.length);
                    Log.output(_actualIndex);
                    _result = eval(_exp);
                }
                else {//likely old command is lingering...
                    continue;
                }
            }
            else {
                continue;
            }

        }
        catch (err) {
            Log.result("error", "Input: " + (_exp ? _exp.toString() : "null") +
                  ". Error: " + err.toString() + "  " +
                  (err.stack ? err.stack.toString() : ""));
            _expectedIndex++;
            continue;
        }

        _expectedIndex = Math.max(_actualIndex+1, _expectedIndex+1);
        Log.result("success", _result);
        target.delay(0.1);
    }
}
