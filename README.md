# MuSmith
MuSmith is like a mini music controller that obviously can control music (previous track, pause/play, next track) it also has a rotary encoder and an oled screen. For the buttons it has mechanical switches.

## Difficulties
For the difficulties i was pretty much the same as my last project [Clicksmith](https://github.com/aleksaingh/clicksmith). The case in Fusion 360 was really messing with me, I spent a good time with designing it.

## Features:
  + Fully 3D printed case
  + 3 Keys
  + A rotary encoder
  + And a 0.91" oled screen
## Firmware
The firmware is a custom circuitpython script (That I and AI made) and a janky Powershell script (This one AI made) that runs at startup. Why? Because i couldn't think of a better way to capture the song and the artist to display on the OLED. The rotary encoder controls the volume and the keys as said in the begining go to the previous track - play/pause - go to the next track.

## OLED screen
As i said the oled is a 0.91" screen that displays the current song and the artist. If i really want it i will maybe add the current time and the progress bar also.

## BOM
What's needed to make this
  + 1x case (2 3D printed parts)
  + 4x M3x5x4 heatset inserts
  + 4x M3x16 screws
  + 3x Cherry MX Switches
  + 3x Cherry DSA keycaps
  + 1x EC11 Rotary encoder
  + 1x XIAO RP2040
  + 1x 0.91" OLED

That's All! 👋

# Images and other nerdy stuff

## CAD

Case was made in Fusion 360.

The top and bottom halves of the case fit together using four heatset inserts and four M3 Screws.

<img width="1920" height="842" alt="Fusion360_EEurYrP4EO" src="https://github.com/user-attachments/assets/13cec363-4f58-4b75-9fea-544f34481a6f" />

## PCB

The PCB was made in KiCad pretty fast.

<img width="1626" height="836" alt="kicad_DkRULZKsaH" src="https://github.com/user-attachments/assets/9549372b-25a4-44e3-a046-f907c83a251c" />

## Schematic

<img width="1920" height="1080" alt="Fusion360_sgYUJH9XTz" src="https://github.com/user-attachments/assets/b4a5e1fa-7845-4da2-9157-028ba2155c6d" />

## Credits
Thank you [DinoMito1](https://github.com/DinoMito1) for giving me inpso for the readme (some parts i stole and changed but we don't talk about that)
