if(typeof JSON!=='object'){JSON={};}
(function(){'use strict';function f(n){return n<10?'0'+n:n;}
if(typeof Date.prototype.toJSON!=='function'){Date.prototype.toJSON=function(key){return isFinite(this.valueOf())?this.getUTCFullYear()+'-'+
f(this.getUTCMonth()+1)+'-'+
f(this.getUTCDate())+'T'+
f(this.getUTCHours())+':'+
f(this.getUTCMinutes())+':'+
f(this.getUTCSeconds())+'Z':null;};String.prototype.toJSON=Number.prototype.toJSON=Boolean.prototype.toJSON=function(key){return this.valueOf();};}
var cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,escapable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,gap,indent,meta={'\b':'\\b','\t':'\\t','\n':'\\n','\f':'\\f','\r':'\\r','"':'\\"','\\':'\\\\'},rep;function quote(string){escapable.lastIndex=0;return escapable.test(string)?'"'+string.replace(escapable,function(a){var c=meta[a];return typeof c==='string'?c:'\\u'+('0000'+a.charCodeAt(0).toString(16)).slice(-4);})+'"':'"'+string+'"';}
function str(key,holder){var i,k,v,length,mind=gap,partial,value=holder[key];if(value&&typeof value==='object'&&typeof value.toJSON==='function'){value=value.toJSON(key);}
if(typeof rep==='function'){value=rep.call(holder,key,value);}
switch(typeof value){case'string':return quote(value);case'number':return isFinite(value)?String(value):'null';case'boolean':case'null':return String(value);case'object':if(!value){return'null';}
gap+=indent;partial=[];if(Object.prototype.toString.apply(value)==='[object Array]'){length=value.length;for(i=0;i<length;i+=1){partial[i]=str(i,value)||'null';}
v=partial.length===0?'[]':gap?'[\n'+gap+partial.join(',\n'+gap)+'\n'+mind+']':'['+partial.join(',')+']';gap=mind;return v;}
if(rep&&typeof rep==='object'){length=rep.length;for(i=0;i<length;i+=1){if(typeof rep[i]==='string'){k=rep[i];v=str(k,value);if(v){partial.push(quote(k)+(gap?': ':':')+v);}}}}else{for(k in value){if(Object.prototype.hasOwnProperty.call(value,k)){v=str(k,value);if(v){partial.push(quote(k)+(gap?': ':':')+v);}}}}
v=partial.length===0?'{}':gap?'{\n'+gap+partial.join(',\n'+gap)+'\n'+mind+'}':'{'+partial.join(',')+'}';gap=mind;return v;}}
if(typeof JSON.stringify!=='function'){JSON.stringify=function(value,replacer,space){var i;gap='';indent='';if(typeof space==='number'){for(i=0;i<space;i+=1){indent+=' ';}}else if(typeof space==='string'){indent=space;}
rep=replacer;if(replacer&&typeof replacer!=='function'&&(typeof replacer!=='object'||typeof replacer.length!=='number')){throw new Error('JSON.stringify');}
return str('',{'':value});};}
if(typeof JSON.parse!=='function'){JSON.parse=function(text,reviver){var j;function walk(holder,key){var k,v,value=holder[key];if(value&&typeof value==='object'){for(k in value){if(Object.prototype.hasOwnProperty.call(value,k)){v=walk(value,k);if(v!==undefined){value[k]=v;}else{delete value[k];}}}}
return reviver.call(holder,key,value);}
text=String(text);cx.lastIndex=0;if(cx.test(text)){text=text.replace(cx,function(a){return'\\u'+
('0000'+a.charCodeAt(0).toString(16)).slice(-4);});}
if(/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,'@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,']').replace(/(?:^|:|,)(?:\s*\[)+/g,''))){j=eval('('+text+')');return typeof reviver==='function'?walk({'':j},''):j;}
throw new SyntaxError('JSON.parse');};}}());

var commandPath = "$PATH";
if (!/\/$/.test(commandPath))
{
    commandPath += "/";
}
commandPath += "repl-cmd.txt";

var Log = (function () {
    // According to Appium,
    //16384 is the buffer size used by instruments
    var forceFlush = [],
        N = 0, i = N;
    if ("$MODE" == "FLUSH")
    {
        N = 16384
    }
    while(i--) { forceFlush[i] = "*"; }
    forceFlush = forceFlush.join('');

    return {
        result: function (status, data) {
            UIALogger.logMessage(JSON.stringify({"status":status, "value":data}));
            if (forceFlush.length > 0) {
                UIALogger.logMessage(forceFlush);
            }
        },
        output: function (msg) {
            UIALogger.logMessage(JSON.stringify({"output":msg}));
            if (forceFlush.length > 0) {
                UIALogger.logMessage(forceFlush);
            }
        }
    };
})();

var target = UIATarget.localTarget(),
    host = target.host();

var expectedIndex = 0,//expected index of next command
    actualIndex,//actual index of next command by reading commandPath
    index,//index of ':' char in command
    exp,//expression to be eval'ed
    result,//result of eval
    input,//command
    process;//host command process

while (true)
{
    try
    {
        process = host.performTaskWithPathArgumentsTimeout("/bin/cat",
                                                           [commandPath],
                                                           2);

    } catch (e)
    {
        Log.output("Timeout on cat...");
        target.delay(0.1);
        continue;
    }
    if (process.exitCode != 0)
    {
        Log.output("unable to execute /bin/cat " + commandPath + " exitCode " + process.exitCode + ". Error: " + process.stderr);
    }
    else
    {
        input = process.stdout;
        try
        {
            index = input.indexOf(":", 0);
            if (index > -1) {
                actualIndex = parseInt(input.substring(0,index),10);
                if (!isNaN(actualIndex) && actualIndex >= expectedIndex) {
                    exp = input.substring(index+1, input.length);
                    result = eval(exp);
                }
                else {//likely old command is lingering...
                    continue;
                }
            }
            else {
                continue;
            }

        }
        catch (err)
        {
            Log.result("error", err.toString() + "  " + (err.stack ? err.stack.toString() : ""));
            expectedIndex++;
            continue;
        }

        expectedIndex++;
        Log.result("success",result);

    }
}
