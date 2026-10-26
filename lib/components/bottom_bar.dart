import 'package:chat_app/provider/bottom_navigation_provider.dart';
import 'package:chat_app/screens/account_screen.dart';
import 'package:chat_app/screens/find_friends_screen.dart';
import 'package:chat_app/screens/friends_screen.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/services/app_update_service.dart';
import 'package:chat_app/services/notification_service.dart';
import 'package:chat_app/services/presence_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomBar extends StatefulWidget {
  final String uid;
  final DocumentSnapshot<Map<String, dynamic>>? userData;
  const BottomBar({super.key, required this.uid, required this.userData});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> with WidgetsBindingObserver {
  late final List<Widget> _screens;
  final PresenceService _presenceService = PresenceService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presenceService.initializePresence(widget.uid);
    _screens = [
      HomeScreen(id: widget.uid),
      FriendScreen(id: widget.uid, userData: widget.userData),
      FindFriendsScreen(id: widget.uid, userData: widget.userData),
      AccountScreen(id: widget.uid, userData: widget.userData),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppUpdateService.initRemoteConfig();
      if (mounted) {
        await AppUpdateService.checkAndShowUpdateDialog(context);
      }
    });

    // Initialize notifications, save token to Firestore, and set up listeners
    FirebaseNotificationService().initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _presenceService.initializePresence(widget.uid);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _presenceService.setOffline(widget.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomBar = context.watch<BottomBarProvider>();
    return Scaffold(
      body: IndexedStack(index: bottomBar.currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: bottomBar.currentIndex == 0
                ? Icon(Icons.message)
                : Icon(Icons.message_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: bottomBar.currentIndex == 1
                ? Icon(Icons.people)
                : Icon(Icons.people_outlined),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: bottomBar.currentIndex == 2
                ? Icon(Icons.person_search)
                : Icon(Icons.person_search_outlined),
            label: 'Find Friends',
          ),
          BottomNavigationBarItem(
            icon: bottomBar.currentIndex == 3
                ? Icon(Icons.account_circle)
                : Icon(Icons.account_circle_outlined),
            label: 'Account',
          ),
        ],
        currentIndex: bottomBar.currentIndex,
        onTap: bottomBar.changeIndex,
      ),
    );
  }
}
