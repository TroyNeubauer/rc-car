# RC-Car

## Archtecture
- Car:
  - Comma.ai Panda for multiplexing multiple CAN busses in car into USB interface
  - Rasberry Pi:
    - Connected via ip radio to GCS
    - Receiving commands from GCS, converting to car-specific CAN commands and sending to Panda
    - Transmitting video from webcam to GCS
    - 
- GCS:
  - Connected via ip radio to Car
  - Joystick / G920 for car inputs
  - Monitor for video output / dashboard (speed, killswitch, etc.)

## Possible cars:
The car used needs to be able to stop and resume automonously from a dead stop.
Some early LKAS systems have a minimumm speed thus requiring human intervention to get rolling.

The 22-24 Honda Civic, 21-24 Camry, or 20-22 Corolla can resume from a stop according to [this page](https://comma.ai/vehicles).

Another issue is that the motor used to turn the wheel is designed for simple lanekeeping, so making sharp turns is not possible due to torque limitations. This will be exacerbated off road.
Torque mods are possible, but can be risky. [See this](https://www.reddit.com/r/Comma_ai/comments/15z5cdo/is_hondas_torque_really_that_bad_for_openpilot/).

