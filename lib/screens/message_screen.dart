import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final StorageService _storage = StorageService();

  void _openEditNoteDialog() {
    final controller = TextEditingController(text: _storage.loveNote);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Love Note',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 7,
          decoration: InputDecoration(
            hintText: 'Write a loving message for your bangaram...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blushPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _storage.updateLoveNote(controller.text.trim());
                setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              'Save Note',
              style: GoogleFonts.poppins(color: AppColors.deepPlum, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _shareNote() {
    final note = _storage.loveNote.replaceAll('[MY NAME]', _storage.myName);
    Share.share('$note\n\n- Sent with love via Do It Now ❤️');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final displayNote = _storage.loveNote.replaceAll('[MY NAME]', _storage.myName);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full Screen Star Photo Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_star.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/images/together_love.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/images/me.jpg', fit: BoxFit.cover),
              ),
            ),
          ),

          // Soft Romantic Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.35),
                    AppColors.nightIndigo.withOpacity(0.75),
                    AppColors.nightIndigo.withOpacity(0.92),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Message from ${_storage.myName} ❤️',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: Colors.white),
                            onPressed: _shareNote,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: AppColors.blushPink, size: 28),
                            onPressed: _openEditNoteDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Hand-Written Style Love Note Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9F0).withOpacity(0.96), // warm parchment cream
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.blushPink,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stamp / Love Wax Seal Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite, color: AppColors.crimsonLove, size: 20)
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.seconds),
                              const SizedBox(width: 8),
                              Text(
                                'To My Dearest Bujji ❤️',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepPlum,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.blushPink.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Only For You 💕',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepPlum,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFE8D3C0), thickness: 1),
                      const SizedBox(height: 12),

                      // Hand-written Love Note
                      Text(
                        displayNote,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF33202C),
                        ),
                      ).animate().fadeIn(duration: 600.ms),

                      const SizedBox(height: 16),

                      // Handwritten signature style
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forever Yours,\n${_storage.myName} ❤️',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.caveat(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB52B4B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

