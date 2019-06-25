#!/usr/bin/expect -f
 
set timeout -1

spawn ssh root@magento.default -p 30022 -o "StrictHostKeyChecking no" -- 'php' '-i'

expect "root@magento.default's password: "
 
send "123123q\r"

expect eof
