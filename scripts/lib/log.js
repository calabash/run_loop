var Log = (function () {
    var forceFlush = [];
    var N = "$FLUSH_LOGS" == "FLUSH_LOGS" ? 16384 : 0;
    var i = N;
    while (i--) {
        forceFlush[i] = "*";
    }
    forceFlush = forceFlush.join('');

    function log_json(object)
    {
        UIALogger.logMessage("OUTPUT_JSON:\n"+JSON.stringify(object)+"\nEND_OUTPUT");
        if (forceFlush.length > 0) {
            UIALogger.logMessage(forceFlush);
        }
    }

    return {
        result: function (status, data) {
            log_json({"status": status, "value": data, "index":_actualIndex});
        },
        output: function (msg) {
            log_json({"output": msg,"last_index":_actualIndex});
        }
    };
})();
