# LAPSER

Lapser is a simple script that comes from my own need to record what I do while programming.
Reasons:

* Ability to show your client what you actually did
* Abliliy to re-watch what you did during development
* Self-discipline motivated by the feeling of making a documentary about writing your software

## Nice features:

* Super light. A screencast is really expensive. Lapser isn't
* It takes one screenshot every 15 seconds. The created video has 4 frames per second. This means that for every second you watch, you watch a minute of real life and for every minute, you watch one hour
* Ability to have different independent profiles
* A nice timestamp and specific label is added to each screenshot (and therefore the movie)
* The screenshots for a timelaps are firstly archived, and then converted to a movie in MP4 format
* Dependencies are simply ffmpeg, Imagemagick and Yad

## Limitations

* Upload of videos to remote server not yet implemented (coming as soon as I need it)
* Dual monitor is not yet managed

## Demo

This is a demo of what will come out. Please note that this _actually_ covers the full development of Lapser: I ran just the script to make 1 screenshot every 15 seconds, and then developed all of the app with the script going. I then fed those screenshots back to Lapser.

You can see at the beginning how I got stuck (really stuck!) with the problem that FFMPEG will not work properly if the input file has a semicolon in it. The rest of the work was about learning YAD and getting the program to actually work.

The girl in the background is my wife Chiara.

[![Lapser in action](http://img.youtube.com/vi/Yj-2S86I6fo/0.jpg)](http://www.youtube.com/watch?v=Yj-2S86I6fo "Lapser in action")


## Final notes

I wrote this in less than 2 days, and with very rusty knowledge of bash.
