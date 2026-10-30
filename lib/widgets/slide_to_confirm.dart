import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class SlideToConfirm extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String text;
  final double height;
  final double borderRadius;

  const SlideToConfirm({
    super.key,
    required this.onConfirmed,
    this.text = 'Slide to take ❤️',
    this.height = 64.0,
    this.borderRadius = 32.0,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _position = 0.0;
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxSlide = constraints.maxWidth - widget.height;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Center Label
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),

              // Active fill background as slider moves
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _position + widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.mintSuccess.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
              ),

              // Draggable Heart Knob
              Positioned(
                left: _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _position = (_position + details.delta.dx).clamp(0.0, maxSlide);
                    });
                    if (_position >= maxSlide * 0.95 && !_isConfirmed) {
                      _isConfirmed = true;
                      HapticFeedback.heavyImpact();
                      widget.onConfirmed();
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    if (!_isConfirmed) {
                      setState(() {
                        _position = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: widget.height,
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: AppColors.heartButtonGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7E9E).withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

