import 'dart:convert';
import 'package:chat_app/components/bottom_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pinput/pinput.dart';

class ConfirmPinScreen extends StatefulWidget {
  final String id;
  final String pin;
  const ConfirmPinScreen({super.key, required this.id, required this.pin});

  @override
  State<ConfirmPinScreen> createState() => _ConfirmPinScreenState();
}

class _ConfirmPinScreenState extends State<ConfirmPinScreen> {
  late TextEditingController pinController;
  String? pinError;
  bool isPinError = false;
  final _formKey = GlobalKey<FormState>();

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    pinController = TextEditingController();
  }

  void createPin() async {
    setState(() {
      isPinError = false;
      pinError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 1. Check if confirm PIN matches the original PIN
    if (pinController.text != widget.pin) {
      setState(() {
        isPinError = true;
        pinError = '*PIN does not match. Please try again.';
      });
      _formKey.currentState!.validate();
      return;
    }

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.id)
        .get();

    EasyLoading.dismiss();
    EasyLoading.showSuccess('PIN created successfully!');

    try {
      // Get the current user's UID
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? widget.id;

      final String hashedPin = hashPin(pinController.text.trim(), uid);

      // 4. Save the hashed string to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'pin':
            hashedPin, // Saves a secure string like "a665a45920422f9d417e4867efdc4fb8..."
        'hasPin': true, // Handy flag to check if setup is complete
      }, SetOptions(merge: true));

      EasyLoading.dismiss();
      EasyLoading.showSuccess('PIN created successfully!');

      // 5. Navigate to Home Screen or next flow safely
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BottomBar(uid: uid, userData: userData),
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Failed to save PIN. Please try again.');
      print("Error saving PIN: $e");
    }
  }

  String hashPin(String rawPin, String userUid) {
    // A unique salt combined with the user's UID to prevent rainbow table attacks
    final String salt = "ChatApp_Secure_Salt_2026_$userUid";
    final String saltedPin = rawPin + salt;

    final List<int> bytes = utf8.encode(saltedPin);
    final Digest digest = sha256.convert(bytes);

    return digest.toString(); // Returns a irreversible 64-character hex string
  }

  @override
  void dispose() {
    focusNode.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Confirm your 6 digit MPIN",
                    style: TextStyle(
                      fontSize: 28,
                      color: Color(0XFF1b374d),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "Enter your six (6) digit pin to confirm.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Pinput(
                    length: 6,
                    controller: pinController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    focusNode: focusNode,
                    onCompleted: (pin) => {},
                    defaultPinTheme: PinTheme(
                      width: 44,
                      height: 48,
                      textStyle: const TextStyle(
                        fontSize: 22,
                        color: Color(0XFF1b374d),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    errorPinTheme: PinTheme(
                      width: 44,
                      height: 48,
                      textStyle: const TextStyle(
                        fontSize: 22,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      height: 56,
                      width: 52,
                      textStyle: const TextStyle(
                        fontSize: 22,
                        color: Color(0XFF1b374d),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0XFF1b374d)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your PIN';
                      }

                      if (isPinError && pinError != null) {
                        return pinError; // Returns the "Incorrect PIN" string from your verification method
                      }
                      if (value.length < 6) {
                        return 'PIN must be 6 digits';
                      }
                      if (value != widget.pin) {
                        return 'PIN does not match';
                      }
                      return null;
                    },
                    onSubmitted: (pin) {
                      createPin();
                    },
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0XFF1b374d),
                    ),
                    onPressed: createPin,
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
