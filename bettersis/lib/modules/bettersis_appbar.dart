import 'package:bettersis/screens/Dashboard/admin_dashboard.dart';
import 'package:bettersis/screens/Dashboard/dashboard.dart';
import 'package:bettersis/screens/Dashboard/teacher_dashboard.dart';
import 'package:bettersis/utils/utils.dart';
import 'package:flutter/material.dart';

class BetterSISAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogout;
  final ThemeData theme;
  final String title;

  const BetterSISAppBar({
    super.key,
    required this.onLogout,
    required this.theme,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    void navigateToDashboard() {
      Map<String, dynamic> userData = Utils.getUser();
      switch (userData['type']) {
        case 'student':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Dashboard(userData: userData),
            ),
          );
          break;
        case 'teacher':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDashboard(userData: userData),
            ),
          );
          break;
        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboard(userData: userData),
            ),
          );
          break;
        default:
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.secondaryHeaderColor, theme.primaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          tooltip: 'Menu',
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              InkWell(
                onTap: navigateToDashboard,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Text(
                    'BetterSIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
