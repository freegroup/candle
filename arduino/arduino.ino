#include <ESP32Servo.h>
#include <PID_v1_bc.h>
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <NimBLEDevice.h>
#include <NimBLEServer.h>
#include <NimBLEUtils.h>
#include <NimBLECharacteristic.h>
#include <cmath> // Fügen Sie diese Zeile am Anfang Ihres Codes ein

// Define the BLE service and characteristic UUIDs
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

NimBLECharacteristic *commandCharacteristic;
NimBLEServer* server;

// BNO055 Sensor
Adafruit_BNO055 bno = Adafruit_BNO055(55);
imu::Vector<3> euler;

// PID variables
double compasAngle = 160.0;    // Target servoAngle to achieve
double servoAngle = 0.0;       // Current servoAngle read from the feedback pin
double targetAngle = 0;

// Parallax 360 Servo variables
int PIN_FEEDBACK = 32;
int PIN_SERVO = 27;

// Instantiate the PID and Servo instances
Servo servo;

class CommandCharacteristicCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pCharacteristic) {
      // Handle the write event here
      std::string value = pCharacteristic->getValue();
      if (value.length() > 0) {
        int angle = std::stoi(value); // Convert string to integer

        // Check if the received angle is within the valid range
        if(angle >= 0 && angle <= 359) {
          targetAngle = angle;
          Serial.println("*********");
          Serial.print("Received command: ");
          Serial.println(targetAngle);
          Serial.println("*********");
        } else {
          Serial.println("Received invalid angle. Ignored.");
        }
      }
    }
};

CommandCharacteristicCallbacks commandCallbacks;

void setup() 
{ 
  Serial.begin(115200);
  
  // BNO055 Sensor initialisieren
  if (!bno.begin()) {
    Serial.print("Es konnte keine Verbindung zum BNO055 hergestellt werden");
    while (1);
  }
  delay(500);

  // Initialize the BLE library
  NimBLEDevice::init("My BLE Device");

  // Setup BLE
  server = NimBLEDevice::createServer();
  NimBLEService *service = server->createService(SERVICE_UUID);
  commandCharacteristic = service->createCharacteristic(CHARACTERISTIC_UUID, NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::NOTIFY);
  commandCharacteristic->setCallbacks(&commandCallbacks);
  service->start();
  server->getAdvertising()->start();
  Serial.println("BLE peripheral device started advertising");

  // Servo initialization
  servo.attach(PIN_SERVO, 1280, 1720);
  servo.setPeriodHertz(50);

  pinMode(PIN_FEEDBACK, INPUT);
} 
  
void loop() 
{
  euler = bno.getVector(Adafruit_BNO055::VECTOR_EULER);
  //  compasAngle = euler.x();
  compasAngle = fmod((euler.x() + targetAngle + 360), 360.0);

  unsigned long pulseWidth = pulseIn(PIN_FEEDBACK, HIGH, 25000);
  servoAngle = 360-map(pulseWidth, 30, 1067, 0, 360);

  // Calculate the difference between compasAngle and servoAngle
  float diffAngle = compasAngle - servoAngle;
  //Serial.print("diffAngle Diff: ");
  //Serial.println(diffAngle);

  // Normalize the difference to be between -180 and 180
  if (diffAngle > 180) {
    diffAngle -= 360;
  } else if (diffAngle < -180) {
    diffAngle += 360;
  }

  servo.write(diffAngle); //Move the servo
  delay(10);
}


