# Hand Sign Language Recognition with MQTT protocol

## Getting Started

This project is a part of Multi Discipline Project course that I anticipated in 2022.

The application recognizes the hand sign in terms of video/images and translate it to text/speech using deep learning. It will help the disadvantages communicate with others without any language barriers. 

## How it works
The application connects with Arduino ESP32 Camera through WebSocket within same WiFi connection, receives signal from Adafruit to start and stop recording video.
After getting stop signal from Adafruit, it will stop video streaming, packetize and send to server to process the signal and return the correct sign pose. 

Reference video: [Youtube](https://youtu.be/Y0pJ8isd8jI)
