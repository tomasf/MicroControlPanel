const int pinRetractButton = 2;
const int pinExtractButton = 3;
const int pinRaiseButton = 4;

const int pinRetractLED = 9;
const int pinExtractLED = 10;
const int pinRaiseLED = 11;

const int pinTestLED = 13;

int ledModes[3] = {0};


void setup() {
  pinMode(pinRetractButton, INPUT_PULLUP);
  pinMode(pinExtractButton, INPUT_PULLUP);
  pinMode(pinRaiseButton, INPUT_PULLUP);

  pinMode(pinRetractLED, OUTPUT);
  pinMode(pinExtractLED, OUTPUT);
  pinMode(pinRaiseLED, OUTPUT);

  Serial.begin(9600);
}


void loop() {
  if(Serial.available() >= 3) {
    uint8_t command = Serial.read();
    uint8_t index = Serial.read()-'0';
    uint8_t value = Serial.read()-'0';
    
    if(command = 'l') {
      if(index < 3) {
        ledModes[index] = value;
      }
    }
  }

  int buttons[3] = {pinRetractButton, pinExtractButton, pinRaiseButton};
  int leds[3] = {pinRetractLED, pinExtractLED, pinRaiseLED};

  for (int b = 0; b < 3; b++) {
    int buttonPin = buttons[b];
    int ledPin = leds[b];
    int ledMode = ledModes[b];
    
    if(ledMode == 0) {
      digitalWrite(ledPin, LOW);
    }else if(ledMode == 1) {
      digitalWrite(ledPin, HIGH);
    }else if(ledMode == 2) {
      long value = millis() % 512;
      if(value < 256) {
        analogWrite(ledPin, value);
      }else{
        analogWrite(ledPin, 255-(value-256));
      }
    }
    
    if (digitalRead(buttonPin) == LOW) {
      Serial.write((char)'b');
      Serial.write((char)b+'0');
      while (digitalRead(buttonPin) == LOW);
      delay(10);
    }
  }
}
