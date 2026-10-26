import 'package:chat_app/components/textformfield.dart';
import 'package:chat_app/provider/theme_provider.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/services/app_update_service.dart';
import 'package:chat_app/services/presence_service.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  final String id;
  final DocumentSnapshot<Map<String, dynamic>>? userData;
  const AccountScreen({super.key, required this.id, required this.userData});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController usernameController;
  late final TextEditingController emailController;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  final _formkey = GlobalKey<FormState>();
  String? usernameError;

  bool isEdit = false;

  void updateUsername() async {
    final newUsername = usernameController.text.trim();

    // 1. Basic validation check before making network calls
    if (newUsername.isEmpty) {
      setState(() {
        usernameError = 'Username cannot be empty.';
        _formkey.currentState?.validate();
      });
      return;
    }

    // 2. Query Firestore for existing username
    final usernameSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: newUsername)
        .limit(1)
        .get();

    // 3. Safety check: ensure widget is still active after async delay
    if (!mounted) return;

    // 4. Check if document exists AND belongs to someone else
    if (usernameSnapshot.docs.isNotEmpty) {
      final existingDoc = usernameSnapshot.docs.first;

      // Only throw error if the matching doc belongs to a DIFFERENT user
      if (existingDoc.id != widget.id) {
        setState(() {
          usernameError = 'Username is already taken.';
          _formkey.currentState?.validate();
        });
        return;
      }
    }

    // 5. Update Firestore if validation passes
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.id)
          .update({'username': newUsername});

      if (!mounted) return;

      setState(() {
        isEdit = false;
        usernameError = null; // Clear error on success
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        usernameError = 'Failed to update username. Try again.';
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Store the stream reference once to prevent recreated listeners
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.id)
        .snapshots();

    usernameController = TextEditingController(
      text: widget.userData?['username'] ?? '',
    );

    emailController = TextEditingController(
      text: widget.userData?['email'] ?? '',
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double wsize = MediaQuery.of(context).size.width;
    final themeState = Provider.of<ThemeProvider>(context);
    bool isDark = themeState.getDarkTheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                // Switches smoothly between Red and your theme's Primary color
                foregroundColor: isEdit
                    ? AppTheme
                          .errorColor // Or Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  isEdit = !isEdit;
                });
              },
              child: Text(isEdit ? 'Cancel' : 'Edit'),
            ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userStream,
          builder: (context, asyncSnapshot) {
            if (!asyncSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var user = asyncSnapshot.data?.data();
            final bool isOnline = user?['isOnline'] ?? false;

            // Only update controller text if the user isn't currently typing
            if (!isEdit &&
                usernameController.text != (user?['username'] ?? '')) {
              usernameController.text = user?['username'] ?? '';
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    child: Text(
                      (user?['username'] ?? '').isNotEmpty
                          ? user!['username'][0].toUpperCase()
                          : '',
                      style: const TextStyle(fontSize: 70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?['username'] ?? '',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text(
                    user?['email'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: wsize * 0.25,
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 222, 253, 187),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline
                                ? const Color.fromARGB(255, 49, 197, 54)
                                : Colors.grey,
                          ),
                        ),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: isOnline
                                ? const Color.fromARGB(255, 49, 197, 54)
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'Personal Details',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  Card(
                    color: isDark ? Colors.black : AppTheme.secondaryColor,
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              enabled: isEdit,
                              controller: usernameController,
                              decoration: textInputDecoration(
                                label: 'Username',
                                errorText: usernameError,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '*Please enter your Username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              enabled: false,
                              readOnly: true,
                              controller: emailController,
                              decoration: textInputDecoration(label: 'Email'),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Email cannot be changed',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isEdit
                                  ? Column(
                                      children: [
                                        const SizedBox(height: 14),
                                        ElevatedButton(
                                          key: const ValueKey('save'),
                                          onPressed: updateUsername,
                                          child: const Text("Save Changes"),
                                        ),
                                      ],
                                    )
                                  : const SizedBox(key: ValueKey('empty')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'Settings',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  Card(
                    color: isDark ? Colors.black : AppTheme.secondaryColor,
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              child: Icon(
                                themeState.getDarkTheme
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                              ),
                            ),
                            title: Text(
                              'Theme',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            trailing: Switch(
                              value: themeState.getDarkTheme,
                              onChanged: (value) {
                                setState(() {
                                  themeState.setDarkTheme = value;
                                });
                              },
                            ),
                          ),
                          Divider(),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              child: const Icon(Icons.security_rounded),
                            ),
                            title: Text(
                              'Change Password',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            onTap: () {
                              // Implement change password functionality here
                            },
                          ),
                          Divider(),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              child: const Icon(Icons.lock_person_outlined),
                            ),
                            title: Text(
                              'Change Pin',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            onTap: () {
                              // Implement change pin functionality here
                            },
                          ),
                          Divider(),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              child: const Icon(Icons.update_rounded),
                            ),
                            title: Text(
                              'Check App Updates',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            onTap: () =>
                                AppUpdateService.checkAndShowUpdateDialog,
                          ),
                          Divider(),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              child: const Icon(Icons.logout_rounded),
                            ),
                            title: Text(
                              'Logout',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            onTap: () async {
                              EasyLoading.show();
                              await PresenceService().setOffline(widget.id);
                              await FirebaseAuth.instance.signOut();

                              Navigator.of(context).pushReplacement(
                                CupertinoPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                              EasyLoading.dismiss();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("v${user!['appVersion']}"),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
