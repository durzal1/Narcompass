import 'package:flutter/material.dart';
import 'package:twilio/twilio.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

Twilio twilio = Twilio(
    accountSid: '***',
    authToken: '***',
    twilioNumber: '+***'); // removed to not post on github

void sendMessage(String phoneNumber, String msg) {
  if (!phoneNumber.startsWith('+')) {
    phoneNumber = "+1" + phoneNumber;
  }
  twilio.messages.sendMessage(phoneNumber, msg);
}
