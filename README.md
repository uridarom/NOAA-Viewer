## Overview

A simple lightweight app for viewing SPC Severe Weather Outlooks on mobile. Built for iOS.
I built this app because I didn't like going on the SPC website every day to check the outlooks, and wanted a nice UI to interact with.

## Making the app

I manually designed the app UI (AppDesignReference.png) and listed the features and capabilities. I then used Claude Opus 4.7 to create an implementation plan (SPC_App_Spec.md). The app was then built following the implementation plan with Claude Code using Sonnet 4.6, with some manual code adjustments when necessary. 

## Installing the app

To install the app, download the repository and build the app on your desired device using XCode (Mac only). 

## Using the app

The app is very simple.
Swipe left or right (or click on the day selector on the top right) to change dates. Choose the specific risk (general, wind, hail, tornado) using the buttons on the bottom (if applicable). Tap on the outlook image to view your specific region. 
Local risks are listed on the top left. The forecast discussion can be read at the bottom. Click the refresh button to check for new outlooks (although the app should update automatically when a new outlook is released). 

<img width="338" height="673" alt="Screenshot 2026-05-24 at 3 37 27 PM" src="https://github.com/user-attachments/assets/be394583-ece8-46f5-9541-a4c0d303a0fb" />
