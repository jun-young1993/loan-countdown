import 'package:flutter/material.dart';
import 'package:flutter_common/constants/juny_constants.dart';
import 'package:flutter_common/flutter_common.dart';
import 'package:flutter_common/models/user/user.dart';

class SettingScreen extends StatelessWidget {
  final Function(User) onUserDeleted;
  const SettingScreen({super.key, required this.onUserDeleted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Tr.app.appInfo.tr()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [],
      ),
      body: SettingScreenLayout(
        appKey: AppKeys.loanCountdown,
        onUserDeleted: onUserDeleted,
      ),
    );
  }
}
