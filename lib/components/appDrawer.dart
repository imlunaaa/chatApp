import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/services/presence_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class appDrawer extends StatelessWidget {
  const appDrawer({
    super.key,
    required this.fname,
    required this.lname,
    required this.userEmail,
    required this.uid,
  });

  final String fname;
  final String lname;
  final String? userEmail;
  final String uid;

  void logout(BuildContext context) async {
    try {
      EasyLoading.show(status: 'Logging out...');

      final String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        // 1. Mark user offline in Firebase
        // await PresenceService().setOffline(uid);
      }

      // 2. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      EasyLoading.dismiss();

      // 3. Optional: Clear root route back to initial state if needed
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      EasyLoading.dismiss();
      print("Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 3,
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$fname $lname',
                      style: const TextStyle(
                        color: Color(0XFF1b374d),
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      '$userEmail',
                      style: const TextStyle(
                        color: Color(0XFF1b374d),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                EasyLoading.show();
                await PresenceService().setOffline(uid);
                await FirebaseAuth.instance.signOut();

                Navigator.of(context).pushReplacement(
                  CupertinoPageRoute(builder: (context) => LoginScreen()),
                );
                EasyLoading.dismiss();
              },
              child: const Card(
                color: Color(0XFF1b374d),
                elevation: 1,
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
