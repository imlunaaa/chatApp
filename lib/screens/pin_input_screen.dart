import 'dart:convert';
import 'package:chat_app/components/bottom_bar.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class PinInputScreen extends StatefulWidget {
  final String id;
  final DocumentSnapshot<Map<String, dynamic>>? userData;
  const PinInputScreen({super.key, required this.id, this.userData});

  @override
  State<PinInputScreen> createState() => _PinInputScreenState();
}

class _PinInputScreenState extends State<PinInputScreen> {
  late TextEditingController pinController;
  String? pinError;
  bool isPinError = false;
  final _formKey = GlobalKey<FormState>();

  late FocusNode focusNode;

  void verifyPin(DocumentSnapshot<Map<String, dynamic>>? data) async {
    setState(() {
      isPinError = false;
      pinError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (data == null || !data.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User data not found.')));
      return;
    }

    // Safe Extraction of stored Hash String
    final String? storedPinHash = data.data()?['pin'];
    if (storedPinHash == null || storedPinHash.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PIN is configured for this account.')),
      );
      return;
    }

    final String enteredRawPin = pinController.text.trim();
    final String uid = widget.id; // Or FirebaseAuth.instance.currentUser!.uid

    // 1. Hash the entered PIN using the exact same function and salt format
    final String enteredPinHash = hashPin(enteredRawPin, uid);

    // 2. Compare the generated hash against the stored hash string
    if (storedPinHash == enteredPinHash) {
      if (!context.mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BottomBar(uid: uid, userData: data),
        ),
      );
    } else {
      // Hash mismatch = Incorrect PIN
      setState(() {
        isPinError = true;
        pinError = '*Incorrect PIN. Please try again.';
      });

      // Re-run form validation to trigger the Pinput red error borders
      _formKey.currentState!.validate();
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
  void initState() {
    super.initState();
    focusNode = FocusNode();
    pinController = TextEditingController();
  }

  @override
  void dispose() {
    focusNode.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IconButton(
                  //   onPressed: () {
                  //     FirebaseAuth.instance.signOut();
                  //   },
                  //   icon: Icon(Icons.logout),
                  // ),
                  Text(
                    "Verification",
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "Hello ${widget.userData?.data()?['username'] ?? 'User'}",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    "Enter your six digit pin to continue.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20.0),
                  Pinput(
                    length: 6,
                    controller: pinController,
                    autofillHints: const [AutofillHints.password],
                    obscureText: true,
                    focusNode: focusNode,
                    onCompleted: (pin) => verifyPin(widget.userData),
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
                      // if (value.length < 6) {
                      //   return 'PIN must be 6 digits';
                      // }
                      if (isPinError && pinError != null) {
                        return pinError; // Returns the "Incorrect PIN" string from your verification method
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: 'Forgot Pin?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {},
                      ),
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
