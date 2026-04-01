import 'package:flutter/material.dart';

import 'home/home_tab.dart';
import 'requests/requests_screen.dart';
import 'training/training_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';
import '../widget/app_svg_icon.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const _accentColor = Color(0xFF1F6BFF);
  static const _mutedColor = Color(0xFF98A2B3);

  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const RequestsScreen(),
    const TrainingScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: 0.06),
              spreadRadius: 1,
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _accentColor,
            unselectedItemColor: _mutedColor,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            elevation: 0,
            items: [
              _buildItem('Home', 'assets/icons/home.svg'),
              _buildItem('Requests', 'assets/icons/request.svg'),
              _buildItem('Trainings', 'assets/icons/training.svg'),
              _buildItem('Community', 'assets/icons/community.svg'),
              _buildItem('Profile', 'assets/icons/profile.svg'),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildItem(String label, String assetName) {
    return BottomNavigationBarItem(
      icon: AppSvgIcon(assetName: assetName, color: _mutedColor),
      activeIcon: AppSvgIcon(assetName: assetName, color: _accentColor),
      label: label,
    );
  }
}
