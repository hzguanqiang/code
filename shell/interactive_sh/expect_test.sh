#!/usr/bin/expect
spawn bash test.sh
expect "enter number:"
send "1\n"
expect "enter name:"
send "bingo\n"
expect off
