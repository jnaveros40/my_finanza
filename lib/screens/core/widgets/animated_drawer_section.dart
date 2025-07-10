// lib/widgets/animated_drawer_section.dart

import 'package:flutter/material.dart';

class AnimatedDrawerSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final List<Widget> children;
  final int animationDelay;

  const AnimatedDrawerSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.color,
    this.animationDelay = 0,
  });

  @override
  State<AnimatedDrawerSection> createState() => _AnimatedDrawerSectionState();
}

class _AnimatedDrawerSectionState extends State<AnimatedDrawerSection>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
      _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));
    
    // Iniciar animación con delay
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionColor = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          child: Column(
            children: [
              // Header de la sección
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: BoxDecoration(
                  color: sectionColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sectionColor.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: sectionColor.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icono de la sección
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: sectionColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 16,
                        color: sectionColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Título de la sección
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: sectionColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    // Línea decorativa
                    Container(
                      width: 24,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            sectionColor.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Elementos de la sección
              ...widget.children,
            ],
          ),
        ),
      ),
    );
  }
}
