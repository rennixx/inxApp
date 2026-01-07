import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_strings.dart';
import 'library_screen.dart';
import 'import_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LibraryScreen(),
    const ImportScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.bookBookmark(PhosphorIconsStyle.thin)),
              activeIcon: Icon(
                PhosphorIcons.bookBookmark(PhosphorIconsStyle.thin),
              ),
              label: AppStrings.navLibrary,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                PhosphorIcons.downloadSimple(PhosphorIconsStyle.regular),
              ),
              activeIcon: Icon(
                PhosphorIcons.downloadSimple(PhosphorIconsStyle.fill),
              ),
              label: AppStrings.navImport,
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.regular)),
              activeIcon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.fill)),
              label: AppStrings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
