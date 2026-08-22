import 'package:chat_app/components/textformfield.dart';
import 'package:chat_app/screens/create_pin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:quickalert/quickalert.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fnameController = TextEditingController();
  final lnameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final typeController = TextEditingController();
  final pinController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpassController = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  String? usernameError;
  String? emailError;
  var obscurePassword = true;
  var htsize;
  void validateInput() {
    if (_formkey.currentState!.validate()) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        text: null,
        title: 'Create Account?',
        confirmBtnText: 'YES',
        cancelBtnText: 'No',
        onConfirmBtnTap: () {
          Navigator.pop(context);
          registerUser();
        },
      );
    }
  }

  void registerUser() async {
    final username = usernameController.text.trim().toLowerCase();

    try {
      EasyLoading.show(status: 'Processing...');
      final usernameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (usernameSnapshot.docs.isNotEmpty) {
        usernameError = 'Username is already taken.';
        _formkey.currentState!.validate();
        EasyLoading.dismiss();
        return;
      }
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );

      if (userCredential.user == null) {
        throw FirebaseAuthException(code: 'null-usercredential');
      }

      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstname': fnameController.text,
        'lastname': lnameController.text,
        'username': usernameController.text,
        'hasPin': false,
        'isOnline': false,
        'email': emailController.text,
        'type': typeController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      EasyLoading.showSuccess('User Account has been registered');
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => CreatePinScreen(id: uid)),
      );
    } on FirebaseAuthException catch (ex) {
      if (ex.code == 'weak-password') {
        EasyLoading.showError(
          'Your password is not secure. Please enter a password with more than 6 characters',
        );
        return;
      }
      if (ex.code == 'email-already-in-use') {
        EasyLoading.showError(
          'your email is already registered. Please enter a new email address',
        );
        return;
      }
      if (ex.code == 'null-usercredential') {
        EasyLoading.showError(
          'An Error occured while creating your account. Plase try again',
        );
        return;
      }
      if (ex.code == 'username-taken') {
        // EasyLoading.showError(
        //   'Username is already taken. Please choose another one.',
        // );
        usernameError = 'Username is already taken.';
        _formkey.currentState!.validate();
        return;
      }
    }
    fnameController.clear();
    lnameController.clear();
    usernameController.clear();
    passwordController.clear();
    confirmpassController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final hsize = MediaQuery.of(context).size.height;
    htsize = hsize;
    return SafeArea(
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(20.0),
          height: htsize,
          child: SingleChildScrollView(
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Register",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text("Please register to login."),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Please enter your First name';
                      }
                      return null;
                    },
                    controller: fnameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    decoration: textInputDecoration(label: "Firstname"),
                  ),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Please enter your Last name';
                      }
                      return null;
                    },
                    controller: lnameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    decoration: textInputDecoration(label: "Lastname"),
                  ),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Please enter your username';
                      }
                      return null;
                    },
                    controller: usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: textInputDecoration(
                      label: "Username",
                      errorText: usernameError,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Please enter an email addrees';
                      }
                      if (!EmailValidator.validate(value)) {
                        return '*Invalid email address';
                      }
                      return null;
                    },
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: textInputDecoration(label: "Email"),
                  ),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Please enter your password';
                      }
                      if (value.length < 6) {
                        return '*Password must not be less than 6 characters';
                      }
                      return null;
                    },
                    controller: passwordController,
                    textInputAction: TextInputAction.next,
                    obscureText: obscurePassword,
                    decoration: textInputDecoration(
                      label: "Password",
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Please confirm your password';
                      }
                      if (value != passwordController.text) {
                        return 'Password don\'t match';
                      }
                      return null;
                    },
                    controller: confirmpassController,
                    textInputAction: TextInputAction.next,
                    obscureText: obscurePassword,
                    decoration: textInputDecoration(label: "Confirm Password"),
                  ),
                  const SizedBox(height: 12.0),
                  ElevatedButton(
                    onPressed: validateInput,
                    child: Text("Sign Up"),
                  ),
                  const SizedBox(height: 12.0),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pop(context);
                              },
                          ),
                        ],
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
