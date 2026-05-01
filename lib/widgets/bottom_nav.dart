import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: AppTheme.gold,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.lineChart),
            label: 'Charts',
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.briefcase),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.messageSquare),
            label: 'AI Chat',
          ),
        ],
      ),
    );
  }
}

class PremiumBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<PremiumBottomNav> createState() => _PremiumBottomNavState();
}

class _PremiumBottomNavState extends State<PremiumBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final isSelected = index == widget.currentIndex;
          final navItems = [
            {'icon': LucideIcons.home, 'label': 'Home'},
            {'icon': LucideIcons.lineChart, 'label': 'Charts'},
            {'icon': LucideIcons.briefcase, 'label': 'Portfolio'},
            {'icon': LucideIcons.map, 'label': 'Map'},
            {'icon': LucideIcons.messageSquare, 'label': 'AI Chat'},
          ];

          return GestureDetector(
            onTap: () {
              _animationController.forward().then((_) {
                _animationController.reverse();
                widget.onTap(index);
              });
            },
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? _scaleAnimation.value : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.gold.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.gold.withOpacity(0.5),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            navItems[index]['icon'] as IconData,
                            size: 20,
                            color: isSelected
                                ? AppTheme.black
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          navItems[index]['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.gold
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
