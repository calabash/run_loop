<%= render_template("lib/json2.min.js") %>
<%= render_template("lib/log.js"); %>
<%= render_template("lib/common.js"); %>

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
