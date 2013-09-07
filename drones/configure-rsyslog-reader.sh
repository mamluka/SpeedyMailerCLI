#!/bin/bash
script_path="`dirname \"$0\"`"
sed -i "s#homedir#${HOME}#g"  $script_path/rsyslog.rb
