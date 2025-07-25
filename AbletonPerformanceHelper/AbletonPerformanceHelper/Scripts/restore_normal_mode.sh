#!/bin/zsh

# Resume paused background processes
pkill -CONT wifiman-desktopd 2>/dev/null
pkill -CONT "MBAM" 2>/dev/null
pkill -CONT grabber 2>/dev/null
pkill -CONT observer 2>/dev/null
pkill -CONT smcwrite 2>/dev/null
pkill -CONT Setapp 2>/dev/null
pkill -CONT Keka 2>/dev/null
pkill -CONT mds 2>/dev/null
pkill -CONT mds_stores 2>/dev/null
