#include <ESP32Servo360.h>

#include <Wire.h>
#include <Adafruit_Sensor.h>
#include "BNO055.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#include <NimBLEDevice.h>
#include <NimBLEServer.h>
#include <NimBLEUtils.h>
#include <NimBLECharacteristic.h>
#include <cmath> // Fügen Sie diese Zeile am Anfang Ihres Codes ein

// Parallax 360 Servo variables
#define SERVO_FEEDBACK  16
#define SERVO_CONTROL   4
#define SERVO_PWM_MIN   1280 
#define SERVO_PWM_MAX   1720

// Bildschirmkonfiguration
#define SCREEN_WIDTH 128 // OLED Displaybreite in Pixeln
#define SCREEN_HEIGHT 32 // OLED Displayhöhe in Pixeln

// Define the BLE service and characteristic UUIDs
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Deklaration für einen SSD1306-Display verbunden mit I2C (SDA, SCL pins)
#define OLED_RESET -1 // Reset-Pin nicht verwendet (manche Versionen benötigen den Pin)
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

NimBLECharacteristic *commandCharacteristic;
NimBLEServer* server;

// BNO055 Sensor
BNO055 bno = BNO055(55);
imu::Vector<3> euler;

// Instantiate the Servo instances
ESP32Servo360 servo;

double compassAngle = 0.0;    // compass angle read from the BNO055
double servoAngle   = 0.0;      // Current servoAngle read from the feedback pin
double targetAngle  = 0.0;      // The angle we want point to


#define NUM_ARRAYS 3
#define ARRAY_SIZE 22
byte data[NUM_ARRAYS][ARRAY_SIZE] = {
    {247, 255, 216, 255, 239, 255, 220, 0, 216, 0, 232, 254, 0, 0, 0, 0, 0, 0, 232, 3, 232, 2},
    {247, 255, 216, 255, 239, 255, 220, 0, 216, 0, 232, 254, 0, 0, 0, 0, 0, 0, 232, 3, 232, 2},
    {247, 255, 216, 255, 239, 255, 220, 0, 216, 0, 232, 254, 0, 0, 0, 0, 0, 0, 232, 3, 232, 2}
};

byte c_data[ARRAY_SIZE];

void calculate_cdata() {
  for(int i=0; i<ARRAY_SIZE; i++) {
    int sum = 0;
    for(int j=0; j<NUM_ARRAYS; j++) {
      sum += data[j][i];
    }
    c_data[i] = sum / NUM_ARRAYS;
  }
}

class CommandCharacteristicCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pCharacteristic) {
      // Handle the write event here
      std::string value = pCharacteristic->getValue();
      if (value.length() > 0) {
        int angle = std::stoi(value); // Convert string to integer

        // Check if the received angle is within the valid range
        if(angle >= 0 && angle <= 359) {
          targetAngle = -angle;
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

class MyServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) {
        Serial.println("Device connected");
    }

    void onDisconnect(NimBLEServer* pServer) {
        Serial.println("Device disconnected");
    }
};

MyServerCallbacks myCallbacks;
CommandCharacteristicCallbacks commandCallbacks;

double getServoAngle() {
  //unsigned long pulseWidth = pulseIn(SERVO_FEEDBACK, HIGH, 25000);
  //return 360-map(pulseWidth, 37, 1046, 0, 360);
  //return servo.getAngle();
  return 360-fmod((servo.getAngle() + 360), 360.0);
}

void setServoAngle(float angle){
  //float value = map(angle, 0, 360, SERVO_PWM_MIN, SERVO_PWM_MAX);
  //servo.writeMicroseconds(value);
  servo.rotateTo(angle);
}

void drawCompass(float angle, float motorAngle) {
  float drawCorrection = 180;
  float drawAngle = 360 - fmod((angle + 360)-drawCorrection, 360.0);

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  int centerX = display.width()/2;
  int centerY = (display.height()/2);  // Adjust this value if needed
  int radius = display.height()/2 -1;  // Adjust this value to change the size of the circle

  // Draw the circle
  display.drawCircle(centerX, centerY, radius, WHITE);

  // Calculate the arrow tip coordinates
  int arrowTipX = centerX + radius * cos((drawAngle - 90) * 3.14 / 180);
  int arrowTipY = centerY + radius * sin((drawAngle - 90) * 3.14 / 180);

  // Draw the arrow
  display.drawLine(centerX, centerY, arrowTipX, arrowTipY, WHITE);

  // Draw the angle in the lower left corner
  display.setCursor(0, SCREEN_HEIGHT - 10); // Set cursor position to start text
  display.println(angle); // Display the angle value

  display.setCursor(SCREEN_WIDTH-40, SCREEN_HEIGHT - 10); // Set cursor position to start text
  display.println(servoAngle); // Display the angle value

  // Update the display
  display.display();
}

void setup() 
{ 
  pinMode(SERVO_FEEDBACK, INPUT);
  pinMode(SERVO_CONTROL, OUTPUT);

  Serial.begin(115200);
  
  // SSD1306_SWITCHCAPVCC = Spannungsversorgung vom 3.3V Pin erzeugen
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) { 
    Serial.println(F("SSD1306 Zuteilung fehlgeschlagen"));
    for(;;); // Endlosschleife, wenn das Display nicht initialisiert wird
  }
  display.clearDisplay();
  display.display();
  
  // BNO055 Sensor initialisieren
  calculate_cdata();
  if (!bno.begin(BNO055::OPERATION_MODE_COMPASS)) {
    Serial.print("Es konnte keine Verbindung zum BNO055 hergestellt werden");
    while (1);
  }
  bno.setCalibData(c_data);
  bno.setExtCrystalUse(true);

  // Initialize the BLE library
  NimBLEDevice::init("Candle");

  // Get the device address
  NimBLEAddress deviceAddress = NimBLEDevice::getAddress();
  std::string deviceAddressStr = deviceAddress.toString();

  Serial.print("Device MAC Address: ");
  Serial.println(deviceAddressStr.c_str());

  // Setup BLE
  server = NimBLEDevice::createServer();
  server->setCallbacks(&myCallbacks);
  
  NimBLEService *service = server->createService(SERVICE_UUID);
  commandCharacteristic = service->createCharacteristic(CHARACTERISTIC_UUID, NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::NOTIFY);
  commandCharacteristic->setCallbacks(&commandCallbacks);
  service->start();
  server->getAdvertising()->start();
  Serial.println("BLE peripheral device started advertising");

  // Servo initialization
  servo.attach(SERVO_CONTROL, SERVO_FEEDBACK);
  servo.setSpeed(60);
  //servo.adjustSignal(SERVO_PWM_MIN, SERVO_PWM_MAX);
  for(int i=0; i<=360; i+=90){
    setServoAngle(i);  // Setzen Sie den Winkel auf 0 Grad (Norden)
    delay(1000);
  }
  setServoAngle(0);
} 
  
void loop() 
{
  euler = bno.getVector(BNO055::VECTOR_EULER);

  compassAngle = fmod((euler.x() + targetAngle + 360), 360.0);
  servoAngle   = getServoAngle();

  // Calculate the difference between compassAngle and servoAngle
  float diffAngle = compassAngle - servoAngle;

  // Normalize the difference to be between -180 and 180
  if (diffAngle > 180) {
    diffAngle -= 360;
  } else if (diffAngle < -180) {
    diffAngle += 360;
  }

  drawCompass(compassAngle, diffAngle);
  if(abs(diffAngle)>2){
    servo.rotate(-diffAngle);
    delay(200);
  }
}


