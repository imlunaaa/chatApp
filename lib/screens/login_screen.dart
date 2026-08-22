import 'package:chat_app/components/textformfield.dart';
import 'package:chat_app/screens/pin_input_screen.dart';
import 'package:chat_app/screens/register_screen.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var obscurePassword = true;
  var htsize;

  String? passwordError;
  String? emailError;

  void login() async {
    passwordError = null;
    EasyLoading.show();
    if (!_formkey.currentState!.validate()) {
      EasyLoading.dismiss();
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );

      String userId = userCredential.user!.uid;
      EasyLoading.dismiss();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (snapshot.exists) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) =>
                PinInputScreen(id: userId, userData: snapshot),
          ),
        );
      } else {
        print('User data not found in Firestore');
        EasyLoading.showError('User data not found.');
        EasyLoading.dismiss();
      }
    } on FirebaseAuthException catch (ex) {
      EasyLoading.dismiss();

      setState(() {
        if (ex.code == 'wrong-password' || ex.code == 'invalid-credential') {
          emailError = '*Invalid email or password';
          passwordError = '*Invalid email or password';
        } else if (ex.code == 'user-not-found') {
          emailError = '*No account found with this email';
        } else {
          passwordError = '*Login failed';
        }
      });
      _formkey.currentState!.validate();

      print(ex.code);
    }
  }

  Future<bool> checkSession() async {
    User? user = await FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }
    return true;
  }

  final _formkey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final hsize = MediaQuery.of(context).size.height;
    htsize = hsize;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            checkSession() == true
                ? IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.home, color: Colors.black),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            height: htsize * 0.60,
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Login",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text("Please Sign in to continue."),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Please enter an email addrees';
                      }

                      return null;
                    },
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: textInputDecoration(
                      errorText: emailError,
                      label: "Email",
                      prefixIcon: Icons.email,
                    ),
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
                    textInputAction: TextInputAction.done,
                    obscureText: obscurePassword,
                    decoration: textInputDecoration(
                      errorText: passwordError,
                      label: "Password",
                      prefixIcon: Icons.lock,
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
                  const SizedBox(height: 16.0),
                  ElevatedButton(onPressed: login, child: Text("Sign In")),
                  const SizedBox(height: 12.0),
                  TextButton(onPressed: () {}, child: Text('Forgot Password?')),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text('OR', style: TextStyle(fontSize: 12)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: 'Dont\'t have account yet? ',
                        style: const TextStyle(fontSize: 15),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => RegisterScreen(),
                                  ),
                                );
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
