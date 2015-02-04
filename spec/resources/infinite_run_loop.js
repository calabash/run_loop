UIALogger.logMessage("Start");

target = UIATarget.localTarget();

while (true) {
  UIALogger.logMessage("In the run loop.");
  target.delay(1);
};

UIALogger.logMessage("End");
