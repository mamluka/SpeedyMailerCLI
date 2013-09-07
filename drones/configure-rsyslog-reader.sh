#!/bin/bash

sed -i "s#homedir#${HOME}#g"  $0/rsyslog.rb