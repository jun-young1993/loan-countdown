import 'package:flutter/material.dart';
import 'package:flutter_common/models/user/user.dart';
import '../screens/add_loan_screen.dart';

class AddLoanButton extends StatelessWidget {
  final User user;
  const AddLoanButton({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddLoanScreen(user: user)),
        );
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }
}
