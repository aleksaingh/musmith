import time
import board
import digitalio
import usb_hid
from adafruit_hid.consumer_control import ConsumerControl
from adafruit_hid.consumer_control_code import ConsumerControlCode
import displayio
import terminalio
from adafruit_display_text import label
import adafruit_displayio_ssd1306
import rotaryio

displayio.release_displays()
i2c = board.I2C()
display_bus = displayio.I2CDisplay(i2c, device_address=0x3C)

splash = displayio.Group()
display.root_group = splash

text_area = label.Label(terminalio.FONT, text="Ready", color=0xFFFF00, x=10, y=30)
splash.append(text_area)

encoder = rotaryio.IncrementalEncoder(board.D3, board.D6)
last_encoder_position = encoder.position

cc = ConsumerControl(usb_hid.devices)

button_config = [
    {
        "pin": board.D7,
        "code": ConsumerControlCode.SCAN_PREVIOUS_TRACK,
        "name": "Previous Track",
    },
    {
        "pin": board.D10,
        "code": ConsumerControlCode.PLAY_PAUSE,
        "name": "Play/Pause",
    },
    {
        "pin": board.A0,
        "code": ConsumerControlCode.SCAN_NEXT_TRACK,
        "name": "Next Track",
    },
]

buttons = []
last_states = []

for config in button_config:
    button = digitalio.DigitalInOut(config["pin"])
    button.direction = digitalio.Direction.INPUT
    button.pull = digitalio.Pull.UP
    buttons.append(button)
    last_states.append(button.value)

print("Ready to control media playback. Press buttons to send commands.")
# 1. buttons
while True:
    for i, button in enumerate(buttons):
        current_state = button.value
        if current_state != last_states[i]:
            if not current_state:
                cc.send(button_config[i]["code"])
                print(f"Sent command: {button_config[i]['name']}")
            last_states[i] = current_state
    time.sleep(0.01)
# 2. rotary encoder
    current_encoder_position = encoder.position
    if current_encoder_position != last_encoder_position:
        if current_encoder_position > last_encoder_position:
            cc.send(ConsumerControlCode.VOLUME_INCREMENT)
            print("Volume Up")
        else:
            cc.send(ConsumerControlCode.VOLUME_DECREMENT)
            print("Volume Down")
        last_encoder_position = current_encoder_position

