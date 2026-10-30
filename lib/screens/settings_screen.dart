import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../services/quote_service.dart';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../utils/battery_optimizer_helper.dart';
import '../widgets/glass_container.dart';
import 'add_edit_medicine_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  bool _isPhoneVisible = false;

  void _showEditNamesDialog() {
    final herCtrl = TextEditingController(text: _storage.herName);
    final myCtrl = TextEditingController(text: _storage.myName);
    final phoneCtrl = TextEditingController(text: _storage.babuPhone);
    bool obscureInput = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Customize Names & Contact',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: herCtrl,
                decoration: const InputDecoration(
                  labelText: 'Her Name',
                  hintText: 'e.g. Bujji',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: myCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your Name (Babu)',
                  hintText: 'e.g. Babu',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                obscureText: obscureInput,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Babu's WhatsApp Number",
                  hintText: 'e.g. 919876543210',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureInput ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureInput = !obscureInput;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blushPink),
              onPressed: () async {
                await _storage.updateNames(
                  herName: herCtrl.text,
                  myName: myCtrl.text,
                );
                await _storage.updateBabuPhone(phoneCtrl.text);
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(color: AppColors.deepPlum, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuotesManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final allQuotes = QuoteService().getAllQuotes();
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.nightIndigo : AppColors.cream,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Telugu Quotes (${allQuotes.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.deepPlum,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.roseGold, size: 28),
                      onPressed: () => _showAddQuoteDialog(setModalState),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: allQuotes.length,
                    itemBuilder: (context, i) {
                      final q = allQuotes[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.nightPlum : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : AppColors.blushPink.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1}.',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.roseGold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q.telugu,
                                    style: GoogleFonts.notoSansTelugu(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : AppColors.deepPlum,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    q.english,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (q.isCustom)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  await _storage.deleteCustomQuote(q.id);
                                  setModalState(() {});
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddQuoteDialog(StateSetter setModalState) {
    final teluguCtrl = TextEditingController();
    final englishCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Loving Quote',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teluguCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Telugu Message',
                hintText: 'మందులు వేసుకో బంగారం ❤️',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: englishCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'English Meaning (Optional)',
                hintText: 'Take your medicine with love ❤️',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blushPink),
            onPressed: () async {
              if (teluguCtrl.text.trim().isNotEmpty) {
                await _storage.addCustomQuote(
                  teluguCtrl.text.trim(),
                  englishCtrl.text.trim(),
                );
                setModalState(() {});
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(
              'Add',
              style: GoogleFonts.poppins(color: AppColors.deepPlum, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showBatteryGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Battery Optimization & Permissions ⚡',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'To make sure reminders ring without fail even when screen is locked or phone is deep-sleeping, please check these 3 steps:\n',
                style: GoogleFonts.poppins(fontSize: 12, height: 1.4),
              ),
              ...BatteryOptimizerHelper.brandGuides.entries.map((entry) {
                final isHighlight = entry.key.contains('Recommended');
                return ExpansionTile(
                  initiallyExpanded: isHighlight,
                  title: Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isHighlight ? const Color(0xFFE85A88) : null,
                    ),
                  ),
                  children: entry.value
                      .map((step) => Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
                            child: Text(step, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mintSuccess),
            onPressed: () async {
              await BatteryOptimizerHelper.requestIgnoreBatteryOptimizations();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              'Request Whitelist ⚡',
              style: GoogleFonts.poppins(color: AppColors.deepPlum, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHiddenPhone(String phone) {
    if (phone.isEmpty) return 'Not configured';
    if (_isPhoneVisible) return phone;
    if (phone.length <= 4) return '••••';
    final last2 = phone.substring(phone.length - 2);
    final prefix = phone.substring(0, 2);
    return '$prefix••••••$last2 (Hidden 🔒)';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.deepPlum,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        children: [
          // Names & WhatsApp Section
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Names & WhatsApp',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: _showEditNamesDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Her Name: ${_storage.herName}',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Name: ${_storage.myName}',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Babu WhatsApp: ${_formatHiddenPhone(_storage.babuPhone)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF25D366),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_storage.babuPhone.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPhoneVisible = !_isPhoneVisible;
                          });
                        },
                        child: Icon(
                          _isPhoneVisible ? Icons.visibility_off : Icons.visibility,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Medicine Reminders Section (Manage & Add Reminders)
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medication_rounded, color: AppColors.roseGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Medicine Reminders',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.lavender : AppColors.blushPink,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(
                        Icons.add,
                        size: 16,
                        color: isDark ? AppColors.nightIndigo : AppColors.deepPlum,
                      ),
                      label: Text(
                        'Add More',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.nightIndigo : AppColors.deepPlum,
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
                        );
                        if (result == true) {
                          await AlarmService().syncAndRescheduleAll();
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_storage.medicines.isEmpty)
                  Text(
                    'No reminders scheduled yet.',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  )
                else
                  ..._storage.medicines.map((med) {
                    final timesStr = med.times.map((t) => AppDateUtils.formatTimeOfDay(t)).join(', ');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.nightPlum : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.alarm_rounded,
                            color: med.isActive ? AppColors.roseGold : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    decoration: med.isActive ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  '$timesStr • ${med.dose} ${med.doseUnit}',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddEditMedicineScreen(medicine: med)),
                              );
                              if (result == true) {
                                await AlarmService().syncAndRescheduleAll();
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Photo Privacy & Screen Theme Section
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined, color: AppColors.roseGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Photo Privacy & Theme',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose background style for lock screen & busy days:',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),

                // Option 1: Serene Nature & Flowers
                InkWell(
                  onTap: () => _storage.setPhotoStyle('nature'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _storage.photoStyle == 'nature'
                          ? AppColors.mintSuccess.withOpacity(0.2)
                          : (isDark ? Colors.white10 : Colors.white70),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _storage.photoStyle == 'nature'
                            ? AppColors.mintSuccess
                            : Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🌿', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Serene Nature & Flowers (Private)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.deepPlum,
                                ),
                              ),
                              Text(
                                'Calm botanical scenery (no personal photos). Perfect for work, public, and busy days.',
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        if (_storage.photoStyle == 'nature')
                          const Icon(Icons.check_circle_rounded, color: AppColors.mintSuccess, size: 20),
                      ],
                    ),
                  ),
                ),

                // Option 2: Our Couple Photos
                InkWell(
                  onTap: () => _storage.setPhotoStyle('couple'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _storage.photoStyle == 'couple'
                          ? AppColors.blushPink.withOpacity(0.2)
                          : (isDark ? Colors.white10 : Colors.white70),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _storage.photoStyle == 'couple'
                            ? AppColors.roseGold
                            : Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('❤️', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Our Sweet Photos',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.deepPlum,
                                ),
                              ),
                              Text(
                                'Shows our personal couple photos with love.',
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        if (_storage.photoStyle == 'couple')
                          const Icon(Icons.check_circle_rounded, color: AppColors.roseGold, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Lock Screen Privacy Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Always use Nature on Lock Screen',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Never shows personal photos when phone is locked or screen is off.',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                  ),
                  value: _storage.lockScreenPrivacy,
                  activeColor: AppColors.mintSuccess,
                  onChanged: (val) => _storage.setLockScreenPrivacy(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Alarm & Sound Options
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alarm & Sound Options',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 12),

                // Selectable Alarm Tones (4 Sounds)
                Text(
                  'Select Alarm Sound:',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blushPink.withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'alarm_chime.wav',
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'alarm_chime.wav', child: Text('1. Gentle Morning Chime 🔔')),
                        DropdownMenuItem(value: 'alarm_sweet_bell.wav', child: Text('2. Sweet Loving Bell 🎵')),
                        DropdownMenuItem(value: 'alarm_urgent_care.wav', child: Text('3. Urgent Care Alert 🚨')),
                        DropdownMenuItem(value: 'alarm_harp.wav', child: Text('4. Celestial Harp 🎼')),
                      ],
                      onChanged: (val) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected alarm sound: $val')),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Snooze duration dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Snooze Time',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    DropdownButton<int>(
                      value: _storage.snoozeDurationMinutes,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 Mins')),
                        DropdownMenuItem(value: 10, child: Text('10 Mins (Default)')),
                        DropdownMenuItem(value: 15, child: Text('15 Mins')),
                      ],
                      onChanged: (val) {
                        if (val != null) _storage.updateSnoozeDuration(val);
                      },
                    ),
                  ],
                ),
                const Divider(),

                // Vibration Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Vibration', style: GoogleFonts.poppins(fontSize: 13)),
                  value: _storage.isVibrationEnabled,
                  activeColor: AppColors.roseGold,
                  onChanged: (val) => _storage.toggleVibration(val),
                ),

                // Sound Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Sound', style: GoogleFonts.poppins(fontSize: 13)),
                  value: _storage.isSoundEnabled,
                  activeColor: AppColors.roseGold,
                  onChanged: (val) => _storage.toggleSound(val),
                ),

                const SizedBox(height: 8),

                // Test Alarm Ring button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: isDark ? AppColors.lavender : AppColors.deepPlum),
                    ),
                    icon: const Icon(Icons.alarm_on, size: 18),
                    label: Text(
                      'Test Alarm Ring (4s)',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await NotificationService().triggerTestAlarm();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test alarm ringing in 4 seconds!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Battery Optimization & Permissions
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.battery_charging_full_rounded, color: AppColors.statusTaken, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Battery Optimization & Permissions ⚡',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Turn on "High background power consumption" and "Autostart" so phone never silences the alarm.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mintSuccess,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.security, color: AppColors.deepPlum, size: 18),
                  label: Text(
                    'Open Whitelist Guide ⚡',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPlum,
                    ),
                  ),
                  onPressed: _showBatteryGuideDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quotes & Customization
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Telugu Quotes Collection',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.format_quote_rounded, color: AppColors.roseGold),
                  title: Text('Manage Telugu Quotes', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Add or view Telugu quotations', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _showQuotesManager,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Backup & Export History
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup & Data',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share, color: AppColors.lavender),
                  title: Text('Export History to WhatsApp', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () {
                    final json = _storage.exportBackupJson();
                    Share.share(json, subject: 'Do It Now Medicine History Backup');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
