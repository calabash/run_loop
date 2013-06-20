#!/bin/bash
sed s/"throw Error"/"throw new Error"/ < /Users/krukow/code/calabash-script/build/calabash_script.js | sed s/"return Error"/"return new Error"/ > ~/code/run_loop/scripts/calabash_script_uia.js && rake install
