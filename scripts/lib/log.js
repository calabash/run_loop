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
