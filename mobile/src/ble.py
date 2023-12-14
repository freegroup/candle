import asyncio
import time
from bleak import BleakClient

# Replace with your device's MAC address
DEVICE_ADDRESS = "CA3D5F69-DA11-8522-3D53-36924668DD09"

# UUIDs from your Arduino code
SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

async def send_test_data(address, service_uuid, char_uuid):
    try:
        async with BleakClient(address) as client:
            connected = await client.is_connected()

            if connected:
                print(f"Connected to {address}")
                
                # Write a test value to the characteristic

                # Send values from 0 to 360
                for i in range(361):
                    test_value = str(i)
                    await client.write_gatt_char(char_uuid, test_value.encode(), response=True)
                    print(f"Sent '{test_value}' to the characteristic {char_uuid}")
                    await asyncio.sleep(0.1)  # Delay of 0.2 seconds

            else:
                print(f"Failed to connect to {address}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Run the async function
loop = asyncio.get_event_loop()
loop.run_until_complete(send_test_data(DEVICE_ADDRESS, SERVICE_UUID, CHARACTERISTIC_UUID))
