#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>

// Instanziieren Sie den BNO055-Sensor
Adafruit_BNO055 bno = Adafruit_BNO055();

void setup() {
  Serial.begin(9600);
  delay(1000);

  if (!bno.begin()) {
    Serial.println("Es konnte keine Verbindung zum BNO055 hergestellt werden");
    while (1);
  }
  delay(1000);
}

void loop() {
  uint8_t system, gyro, accel, mag = 0;
  bno.getCalibration(&system, &gyro, &accel, &mag);

  // Zeigt die Kalibrierungsdaten für jeden Sensor an
  Serial.print("System: ");
  Serial.print(system, DEC);
  Serial.print(" Gyro: ");
  Serial.print(gyro, DEC);
  Serial.print(" Accel: ");
  Serial.print(accel, DEC);
  Serial.print(" Mag: ");
  Serial.println(mag, DEC);

  if (system == 3 && gyro == 3 && accel == 3 && mag == 3) {
    // Wenn alle Sensoren vollständig kalibriert sind, erhalten Sie die Kalibrierungsdaten
    adafruit_bno055_offsets_t calibrationData;
    bno.getSensorOffsets(calibrationData);

    // Zeigen Sie die Kalibrierungsdaten an
    Serial.println("Kalibrierungsdaten:");
    Serial.print("Accelerometer: ");
    Serial.print(calibrationData.accel_offset_x); Serial.print(" ");
    Serial.print(calibrationData.accel_offset_y); Serial.print(" ");
    Serial.println(calibrationData.accel_offset_z);
    Serial.print("Gyroskop: ");
    Serial.print(calibrationData.gyro_offset_x); Serial.print(" ");
    Serial.print(calibrationData.gyro_offset_y); Serial.print(" ");
    Serial.println(calibrationData.gyro_offset_z);
    Serial.print("Magnetometer: ");
    Serial.print(calibrationData.mag_offset_x); Serial.print(" ");
    Serial.print(calibrationData.mag_offset_y); Serial.print(" ");
    Serial.println(calibrationData.mag_offset_z);
  }

  delay(1000);
}
