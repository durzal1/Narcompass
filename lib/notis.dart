import 'package:flutter/material.dart';
import 'package:twilio/twilio.dart';

Twilio twilio = Twilio(
    accountSid:
        'AC2b687b79fd8c14ece1a5766c3f4a8e9a', // replace *** with Account SID
    authToken:
        'c9213f92df3ae0a828ebf4dae1943eb8', // replace xxx with Auth Token
    twilioNumber: '+18334821256' // replace .... with Twilio Number
    );

void sendMessage(String phoneNumber, String msg) {
  if (!phoneNumber.startsWith('+')) {
    phoneNumber = "+1" + phoneNumber;
  }
  twilio.messages.sendMessage(phoneNumber, msg);
}
