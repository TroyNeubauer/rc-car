#!/usr/bin/env python3
from panda import Panda
import opendbc.can.parser as parser
from opendbc.can.packer import CANPacker
from opendbc.car.structs import CarParams
import time
import gzip
import struct
import os

def run_logger():
    panda = Panda()
    panda.set_safety_mode(CarParams.SafetyModel.allOutput)

    log_dir = "./logs"
    os.makedirs(log_dir, exist_ok=True)
    timestamp = int(time.time())
    log_file = f"{log_dir}/{timestamp}--can.log"

    with open(log_file, 'wb') as f:
        while True:
            msgs = panda.can_recv()
            for msg in msgs:
                # Format: timestamp, bus, address, data
                timestamp_us = int(time.time() * 1e6)
                bus = msg[2] if len(msg) > 2 else 0
                address = msg[0]
                data = msg[1]
                
                # Write in candump format for Cabana compatibility
                log_line = f"({timestamp_us:010d}) can{bus} {address:03X}#{data.hex().upper()}\n"
                f.write(log_line.encode())
            
            time.sleep(0.01)

if __name__ == "__main__":
    run_logger()
