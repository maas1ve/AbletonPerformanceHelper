#!/bin/zsh

# Kill background helper apps
killall "CleverFiles BackService" 2>/dev/null
killall leapd 2>/dev/null
killall CodeMeterMacX 2>/dev/null
killall FAHClient 2>/dev/null
killall ACCFinderSync 2>/dev/null

# Pause background processes that are safe to suspend
pkill -STOP wifiman-desktopd 2>/dev/null
pkill -STOP "MBAM" 2>/dev/null
pkill -STOP grabber 2>/dev/null
pkill -STOP observer 2>/dev/null
pkill -STOP smcwrite 2>/dev/null
pkill -STOP Setapp 2>/dev/null
pkill -STOP Keka 2>/dev/null
pkill -STOP mds 2>/dev/null
pkill -STOP mds_stores 2>/dev/null
