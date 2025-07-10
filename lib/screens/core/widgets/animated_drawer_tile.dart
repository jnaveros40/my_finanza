// lib/widgets/animated_drawer_tile.dart

import 'package:flutter/material.dart';

class AnimatedDrawerTile extends StatefulWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;
  final int animationDelay;

  const AnimatedDrawerTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isSelected,
    this.animationDelay = 0,
  });

  @override
  State<AnimatedDrawerTile> createState() => _AnimatedDrawerTileState();
}

class _AnimatedDrawerTileState extends State<AnimatedDrawerTile>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _slideController;
  late Animation<double> _hoverAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // Controlador para efectos hover
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Controlador para animación de entrada
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Animaciones
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar animación de entrada con delay
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: widget.isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  border: widget.isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Animación de tap
                      _hoverController.forward().then((_) {
                        _hoverController.reverse();
                      });
                      widget.onTap();
                    },
                    onHover: _onHover,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 + (_hoverAnimation.value * 4),
                        vertical: 12,
                      ),
                      transform: Matrix4.identity()
                        ..scale(1.0 + (_hoverAnimation.value * 0.02)),
                      child: Row(
                        children: [
                          // Icono con animación
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                                  : Theme.of(context).colorScheme.primary.withOpacity(
                                      0.05 + (_hoverAnimation.value * 0.1)
                                    ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _isHovered || widget.isSelected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              widget.leading,
                              color: widget.isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(
                                      0.7 + (_hoverAnimation.value * 0.3)
                                    ),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Contenido de texto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: widget.isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(
                                            0.9 + (_hoverAnimation.value * 0.1)
                                          ),
                                    fontWeight: widget.isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: widget.isSelected
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(
                                            0.6 + (_hoverAnimation.value * 0.2)
                                          ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Indicador de selección
                          if (widget.isSelected)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 3,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
