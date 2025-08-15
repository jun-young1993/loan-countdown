import 'package:flutter/material.dart';
import '../screens/add_loan_screen.dart';

class AddLoanButton extends StatelessWidget {
  const AddLoanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddLoanScreen(),
          ),
        );
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }
}
