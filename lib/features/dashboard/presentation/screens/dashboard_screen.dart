import 'package:flutter/material.dart';
import '../../../auth/domain/entities/admin_entity.dart';

class DashboardScreen extends StatelessWidget {
  final AdminRole role;
  
  const DashboardScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(role == AdminRole.superAdmin ? 'Super Admin Dashboard' : 'Lounge Admin Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to the Dashboard'),
            const SizedBox(height: 20),
            if (role == AdminRole.superAdmin)
              const Text('This is the Super Admin view (Full Access)')
            else
              const Text('This is the Lounge Admin view (Restricted Access)'),
          ],
        ),
      ),
    );
  }
}
