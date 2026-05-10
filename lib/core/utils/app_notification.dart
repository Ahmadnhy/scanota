import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppNotification {
  static void show(BuildContext context, String message, {bool isError = false, bool isCentered = false}) {
    if (!context.mounted) return;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: isCentered ? null : 60,
        bottom: isCentered ? null : null,
        left: 24,
        right: 24,
        child: isCentered 
          ? Center(
              child: Material(
                color: Colors.transparent,
                child: _NotificationWidget(message: message, isError: isError, isCentered: true),
              ),
            )
          : Material(
              color: Colors.transparent,
              child: _NotificationWidget(message: message, isError: isError, isCentered: false),
            ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isCentered;
  const _NotificationWidget({required this.message, required this.isError, this.isCentered = false});

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
    _slideAnimation = Tween<Offset>(
      begin: widget.isCentered ? const Offset(0, 0.1) : const Offset(0, -0.5), 
      end: Offset.zero
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isError 
                  ? [Colors.redAccent, Colors.red.shade800] 
                  : [AppColors.darkText, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (widget.isError ? Colors.redAccent : Colors.black).withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isError ? Icons.error_outline : Icons.check_circle_outline, 
                    color: Colors.white, 
                    size: 20
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    widget.message,
                    textAlign: widget.isCentered ? TextAlign.center : TextAlign.start,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 15, 
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
