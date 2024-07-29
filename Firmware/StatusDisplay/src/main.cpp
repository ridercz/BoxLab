/*********************************************************************************************************************
 * Lazy Horse Box Lab Status Display                                                      version 1.0.0 (2024-07-19) *
 * ----------------------------------------------------------------------------------------------------------------- *
 * This sketch displays the status of the Lazy Horse Box Lab on a Nokia 5110 LCD. It checks the status of the WiFi   *
 * connection, the internet connection, and the internal server. It uses the Adafruit PCD8544 library to control     *
 * the LCD.                                                                                                          *
 * ----------------------------------------------------------------------------------------------------------------- *
 * Hardware connection LCD -> ESP8266 (Wemos D1 Mini):                                                               *
 * RST --------> D2 (GPIO 4)                                                                                         *
 * CE (CS) ----> D8 (GPIO 15)                                                                                        *
 * DC ---------> D1 (GPIO 5)                                                                                         *
 * DIN (MOSI) -> D7 (GPIO 13)                                                                                        *
 * CLK (SCK) --> D5 (GPIO 14)                                                                                        *
 * VCC --------> 3V3                                                                                                 *
 * GND --------> GND                                                                                                 *
 * ----------------------------------------------------------------------------------------------------------------- *
 * Builtin LED is used to indicate status                                                                            *
 * - Off:                    powered off                                                                             *
 * - On:                     initializing or WiFi FAIL                                                               *
 * - Blinking slowly (1 Hz): everything OK                                                                           *
 * - Blinking fast (10 Hz):  Internet or server FAIL                                                                 *
 * ----------------------------------------------------------------------------------------------------------------- *
 * Copyright (c) Michal Altair Valasek, 2024 | Licensed under terms of the MIT license.                              *
 *               https://www.rider.cz | https://www.altair.blog | https://github.com/ridercz/BoxLab                  *
 *********************************************************************************************************************/

#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_PCD8544.h>
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>

#define WIFI_SSID "boxlab.lazyhorse.net"
#define WIFI_PASS "IHaveHorsePower!"
#define LCD_CONTRAST 35
#define CHECK_INTERVAL 60000
#define CHECK_TTL 90000

#define VERSION "1.0.0"
#define LED_BLINK_INTERVAL_OK 1000
#define LED_BLINK_INTERVAL_FAIL 100
#define STATUS_FAIL 0
#define STATUS_OK 1
#define STATUS_NA -1

Adafruit_PCD8544 display = Adafruit_PCD8544(D5, D7, D1, D8, D2);
WiFiClient wifiClient;
BearSSL::WiFiClientSecure tlsClient;

int displayStatus = STATUS_NA;
int wifiStatus = STATUS_FAIL;
int internetStatus = STATUS_NA;
int serverStatus = STATUS_NA;

unsigned long nextCheckTime = 0;
unsigned long nextBlinkTime = 0;
bool nextBlinkStatus = LOW;

void updateDisplayStatus()
{
  // Print header to serial port
  Serial.printf("Version: %s, Time: %ld, TTL: %i", VERSION, millis(), CHECK_TTL);

  // Print header to display
  display.clearDisplay();
  display.println("  Lazy Horse  ");
  display.println("Box Lab Status");
  display.println("--------------");

  // Print WiFi status
  if (wifiStatus == STATUS_FAIL)
  {
    display.println("WiFi:      ...");
    Serial.print(", WiFi: FAIL");
  }
  else
  {
    display.println("WiFi:       OK");
    Serial.print(", WiFi: OK");
  }

  // Print Internet status
  if (internetStatus == STATUS_FAIL)
  {
    display.println("Internet: FAIL");
    Serial.print(", Internet: FAIL");
  }
  else if (internetStatus == STATUS_OK)
  {
    display.println("Internet:   OK");
    Serial.print(", Internet: OK");
  }
  else
  {
    display.println("Internet:  N/A");
    Serial.print(", Internet: N/A");
  }

  // Print local server status
  if (serverStatus == STATUS_FAIL)
  {
    display.println("Server:   FAIL");
    Serial.print(", Server: FAIL");
  }
  else if (serverStatus == STATUS_OK)
  {
    display.println("Server:     OK");
    Serial.print(", Server: OK");
  }
  else
  {
    display.println("Server:    N/A");
    Serial.print(", Server: N/A");
  }

  display.display();
  Serial.println();
}

void setup()
{
  // Setup internal LED and turn it on (it is active low)
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  // Open serial debugging port
  Serial.begin(9600);
  Serial.println();
  Serial.println("# LazyHorse.net BoxLab Status Display");
  Serial.println("# Version " VERSION);
  Serial.println("# Initializing...");

  // Allow any HTTPS certificate - good enough for this purpose
  tlsClient.setInsecure();

  // Initialize display and show splash screen
  displayStatus = display.begin() ? STATUS_OK : STATUS_FAIL;
  Serial.printf("# Display init result: %s\n", displayStatus ? "OK" : "FAIL");
  display.setContrast(LCD_CONTRAST);
  display.clearDisplay();
  display.setTextColor(BLACK);
  display.setTextSize(2);
  display.println("BOX LAB");
  display.println("VERSION");
  display.println(" " VERSION " ");
  display.display();
  delay(5000);
  display.setTextSize(1);
  Serial.println("# Initialization done");
}

void loop()
{
  // Blink the internal LED
  if (millis() >= nextBlinkTime)
  {
    digitalWrite(LED_BUILTIN, nextBlinkStatus);
    nextBlinkStatus = !nextBlinkStatus;
    nextBlinkTime = millis() + ((internetStatus == STATUS_OK && serverStatus == STATUS_OK) ? LED_BLINK_INTERVAL_OK : LED_BLINK_INTERVAL_FAIL);
  }

  // Check if it is time to check the status
  if (millis() >= nextCheckTime)
  {
    // Check if we are connected to WiFi
    if (WiFi.status() != WL_CONNECTED)
    {
      // Turn on the internal LED (it is active low)
      digitalWrite(LED_BUILTIN, LOW);

      // Print status to serial
      Serial.println("# WiFi not connected, connecting to " WIFI_SSID "...");

      // Display status
      wifiStatus = STATUS_FAIL;
      internetStatus = STATUS_NA;
      serverStatus = STATUS_NA;

      // Connect to WiFi
      WiFi.begin(WIFI_SSID, WIFI_PASS);
      while (WiFi.status() != WL_CONNECTED)
      {
        updateDisplayStatus();
        delay(1000);
      }
    }

    // We are connected to WiFi
    wifiStatus = STATUS_OK;
    updateDisplayStatus();

    // Check if Microsoft NCSI is reachable
    HTTPClient http;
    http.begin(wifiClient, "http://www.msftncsi.com/ncsi.txt");
    internetStatus = http.GET() == 200 ? STATUS_OK : STATUS_FAIL;
    updateDisplayStatus();

    // Check if the internal server is reachable
    http.begin(tlsClient, "https://www.boxlab.lazyhorse.net/");
    serverStatus = http.GET() == 200 ? STATUS_OK : STATUS_FAIL;
    updateDisplayStatus();

    // Set next check time
    nextCheckTime = millis() + CHECK_INTERVAL;
  }
}