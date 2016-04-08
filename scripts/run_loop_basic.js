<%= render_template("lib/json2.min.js") %>
<%= render_template("lib/log.js"); %>
<%= render_template("lib/on_alert.js"); %>

UIATarget.onAlert = function (alert) {
    Log.output({"output":"on alert"});
    var target = UIATarget.localTarget();
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
