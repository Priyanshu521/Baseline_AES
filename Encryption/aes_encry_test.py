import serial
import time

def aes_encryption_utility():
    # --- CONFIGURATION ---
    # Ensure this matches your Windows Device Manager
    SERIAL_PORT = 'COM3' 
    BAUD_RATE = 9600
    
    # --- INPUT VECTORS ---
    # These are the values currently being sent to the Artix-7
    key_hex   = "5468617473206D79204B756E67204675"
    plain_hex = "54776F204F6E65204E696E652054776F"

    try:
        ser = serial.Serial(
            port=SERIAL_PORT, 
            baudrate=BAUD_RATE, 
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            bytesize=serial.EIGHTBITS,
            timeout=3
        )
    except Exception as e:
        print(f"FAILED: Serial port {SERIAL_PORT} could not be opened.")
        print(f"Error: {e}")
        return

    # Convert Hex Strings to binary for the FPGA UART
    key_bytes   = bytes.fromhex(key_hex)
    plain_bytes = bytes.fromhex(plain_hex)

    # --- TERMINAL OUTPUT ---
    print("\n" + "="*45)
    print("      AES-128 ENCRYPTION HARDWARE TEST")
    print("="*45)
    print(f"PORT:      {SERIAL_PORT}")
    print(f"BAUD:      {BAUD_RATE}")
    print("-" * 45)
    print(f"KEY:       {key_hex.upper()}")
    print(f"PLAINTEXT: {plain_hex.upper()}")
    print("-" * 45)
    print("Communicating with Basys 3...")

    # Send data blocks
    ser.write(key_bytes)
    ser.write(plain_bytes)

    # Wait for the 50-cycle BRAM computation and UART TX shift-out
    time.sleep(0.1)

    # Read the 16-byte response
    received_data = ser.read(16)

    print("-" * 45)
    if len(received_data) == 16:
        ciphertext = received_data.hex().upper()
        print(f"RESULT (CIPHERTEXT): {ciphertext}")
    else:
        print(f"ERROR: Received {len(received_data)} bytes.")
        print("Suggestion: Press the Center Button (U18) to reset FSM.")
    
    print("="*45 + "\n")

    ser.close()

if __name__ == "__main__":
    aes_encryption_utility()
