import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staffportal/core/providers/app_providers.dart';
import 'package:staffportal/features/home/views/home_tab.dart';
import 'package:staffportal/features/requests/views/requests_screen.dart';
import 'package:staffportal/features/training/views/training_screen.dart';
import 'package:staffportal/features/community/views/community_screen.dart';
import 'package:staffportal/features/profile/views/profile_screen.dart';
import 'package:staffportal/core/widgets/app_svg_icon.dart';
import 'package:staffportal/core/widgets/responsive_layout.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  static const _accentColor = Color(0xFF1F6BFF);
  static const _mutedColor = Color(0xFF98A2B3);

  int _currentIndex = 0;
  int _profileReloadVersion = 0;

  List<Widget> get _screens => [
    const HomeTab(),
    const RequestsScreen(),
    const TrainingScreen(),
    const CommunityScreen(),
    ProfileScreen(key: ValueKey(_profileReloadVersion)),
  ];

  void _reloadTabData(int index) {
    switch (index) {
      case 0:
        ref.read(staffRequestsViewModelProvider.notifier).refresh();
        ref.read(peerExchangeViewModelProvider.notifier).loadAll();
        break;
      case 1:
        ref.read(staffRequestsViewModelProvider.notifier).refresh();
        break;
      case 2:
        ref.read(trainingViewModelProvider.notifier).refresh();
        break;
      case 3:
        ref.read(peerExchangeViewModelProvider.notifier).loadAll();
        break;
      case 4:
        setState(() {
          _profileReloadVersion++;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final useRail = AppBreakpoints.isTablet(context);
    return Scaffold(
      body: useRail
          ? Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() => _currentIndex = index);
                      _reloadTabData(index);
                    },
                    extended:
                        MediaQuery.sizeOf(context).width >=
                        AppBreakpoints.desktop,
                    minExtendedWidth: 190,
                    backgroundColor: Colors.white,
                    selectedIconTheme: const IconThemeData(color: _accentColor),
                    unselectedIconTheme: const IconThemeData(
                      color: _mutedColor,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: _mutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                    destinations: [
                      _buildRailDestination('Home', 'assets/icons/home.svg'),
                      _buildRailDestination(
                        'Requests',
                        'assets/icons/request.svg',
                      ),
                      _buildRailDestination(
                        'Trainings',
                        'assets/icons/training.svg',
                      ),
                      _buildRailDestination(
                        'Community',
                        'assets/icons/community.svg',
                      ),
                      _buildRailDestination(
                        'Profile',
                        'assets/icons/profile.svg',
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFE4E7EC)),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: _screens),
                ),
              ],
            )
          : IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: useRail
          ? null
          : Container(
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
                    _reloadTabData(index);
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

  NavigationRailDestination _buildRailDestination(
    String label,
    String assetName,
  ) {
    return NavigationRailDestination(
      icon: AppSvgIcon(assetName: assetName, color: _mutedColor),
      selectedIcon: AppSvgIcon(assetName: assetName, color: _accentColor),
      label: Text(label),
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
