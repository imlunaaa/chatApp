import 'package:chat_app/screens/confirm_pin_screen.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class CreatePinScreen extends StatefulWidget {
  final String id;
  const CreatePinScreen({super.key, required this.id});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
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
                    "Create your 6 digit MPIN",
                    style: TextStyle(
                      fontSize: 32,
                      color: Color(0XFF1b374d),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "Enter six (6) digit pin to continue.",
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
                      if (value.length < 6) {
                        return 'PIN must be 6 digits';
                      }
                      if (isPinError && pinError != null) {
                        return pinError; // Returns the "Incorrect PIN" string from your verification method
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0XFF1b374d),
                    ),
                    onPressed: () {
                      setState(() {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        if (_formKey.currentState!.validate()) {
                          // If the form is valid, navigate to the ConfirmPinScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmPinScreen(
                                id: widget.id,
                                pin: pinController.text,
                              ),
                            ),
                          );
                        }
                      });
                    },
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
