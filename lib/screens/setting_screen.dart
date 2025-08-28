import 'package:flutter/material.dart';
import 'package:flutter_common/constants/juny_constants.dart';
import 'package:flutter_common/flutter_common.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Tr.app.appInfo.tr()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [],
      ),
      body: const SettingScreenLayout(appKey: AppKeys.loanCountdown),
    );
  }
}
