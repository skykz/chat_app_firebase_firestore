import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/screens/auth/auth_screen.dart';


void printWrapped(String text) {
  final pattern = new RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

double screenAwareHeight(double height, BuildContext context) {
  return height * MediaQuery.of(context).size.height / 1920;
}

double screenAwareWidth(double width, BuildContext context) {
  return width * MediaQuery.of(context).size.width / 1080;
}

signOut(BuildContext context) async {

  await FirebaseAuth.instance.signOut();

  Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(pageBuilder: (BuildContext context, Animation animation,
          Animation secondaryAnimation) {
        return AuthorizationScreen();
      }, transitionsBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        return new SlideTransition(
          position: new Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      }),
      (Route route) => false);
  // exit(0);
}


