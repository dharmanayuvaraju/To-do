import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/glass_container.dart';

class AddEditMedicineScreen extends StatefulWidget {
  final Medicine? medicine;

  const AddEditMedicineScreen({super.key, this.medicine});

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _doseController;
  late TextEditingController _noteController;

  String _doseUnit = 'Tablet';
  List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];
  List<int> _daysOfWeek = [1, 2, 3, 4, 5, 6, 7];
  int _selectedColor = 0xFFF8C8DC;

  final List<String> _doseUnits = [
    'Tablet',
    'Capsule',
    'Spoon (ml)',
    'Drops',
    'Injection',
    'Powder / Sachet',
  ];

  final List<int> _colorPalette = [
    0xFFF8C8DC, // Blush Pink
    0xFFCDB4F6, // Lavender
    0xFFA8E6CF, // Mint Success
    0xFFFFD6BA, // Soft Peach
    0xFFFFF3B0, // Pastel Yellow
    0xFFE8DEF8, // Soft Lilac
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    _nameController = TextEditingController(text: m?.name ?? '');
    _doseController = TextEditingController(text: m?.dose ?? '1');
    _noteController = TextEditingController(text: m?.note ?? '');

    if (m != null) {
      _doseUnit = m.doseUnit;
      _times = List.from(m.times);
      _daysOfWeek = List.from(m.daysOfWeek);
      _selectedColor = m.colorValue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({int? editIndex}) async {
    final initial = editIndex != null ? _times[editIndex] : TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.deepPlum,
              onPrimary: Colors.white,
              surface: AppColors.cream,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (editIndex != null) {
          _times[editIndex] = picked;
        } else {
          _times.add(picked);
        }
        // Keep sorted
        _times.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('కనీసం ఒక సమయం ఎంచుకోండి / Add at least 1 reminder time')),
      );
      return;
    }

    final medicine = Medicine(
      id: widget.medicine?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dose: _doseController.text.trim(),
      doseUnit: _doseUnit,
      times: _times,
      daysOfWeek: _daysOfWeek.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : _daysOfWeek,
      note: _noteController.text.trim(),
      colorValue: _selectedColor,
      isActive: widget.medicine?.isActive ?? true,
      createdAt: widget.medicine?.createdAt ?? DateTime.now(),
    );

    await StorageService().saveMedicine(medicine);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.medicine != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'మందు సవరించు / Edit Medicine' : 'కొత్త మందు చేర్చు / Add Medicine',
          style: GoogleFonts.notoSansTelugu(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.deepPlum,
          ),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Medicine?'),
                    content: const Text('ఈ మందును తొలగించాలనుకుంటున్నారా?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await StorageService().deleteMedicine(widget.medicine!.id);
                  if (mounted) Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.nightSkyGradient
              : AppColors.creamLavenderGradient,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Medicine Name
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'మందు పేరు / Medicine Name *',
                      style: GoogleFonts.notoSansTelugu(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Folic Acid / ఫోలిక్ యాసిడ్',
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.medication_outlined, color: AppColors.roseGold),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'పేరు రాయండి / Enter name' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Dose & Dose Unit
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'డోస్ & పరిమాణం / Dose & Unit',
                      style: GoogleFonts.notoSansTelugu(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Dose input
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _doseController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: '1',
                              filled: true,
                              fillColor: isDark ? Colors.black26 : Colors.white.withOpacity(0.8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Dose Unit Dropdown
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _doseUnit,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                items: _doseUnits.map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(u, style: GoogleFonts.poppins(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _doseUnit = val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Reminder Times List
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'రిమైండర్ సమయాలు / Reminder Times',
                          style: GoogleFonts.notoSansTelugu(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _pickTime(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('సమయం చేర్చు'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(_times.length, (index) {
                        final t = _times[index];
                        return Chip(
                          backgroundColor: isDark
                              ? AppColors.nightPlum
                              : AppColors.lavender.withOpacity(0.3),
                          avatar: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.crimsonLove),
                          label: Text(
                            AppDateUtils.formatTimeOfDay(t),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? Colors.white : AppColors.deepPlum,
                            ),
                          ),
                          deleteIcon: _times.length > 1
                              ? const Icon(Icons.close, size: 16)
                              : null,
                          onDeleted: _times.length > 1
                              ? () => setState(() => _times.removeAt(index))
                              : null,
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Days of week selector
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ఏ రోజుల్లో వేసుకోవాలి? / Days of Week',
                      style: GoogleFonts.notoSansTelugu(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final dayNumber = i + 1; // 1 = Mon .. 7 = Sun
                        final isSelected = _daysOfWeek.contains(dayNumber);
                        final label = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                if (_daysOfWeek.length > 1) {
                                  _daysOfWeek.remove(dayNumber);
                                }
                              } else {
                                _daysOfWeek.add(dayNumber);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected ? AppColors.heartButtonGradient : null,
                              color: isSelected
                                  ? null
                                  : (isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isDark ? Colors.white24 : Colors.black12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : AppColors.deepPlum),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Loving Note
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ప్రేమతో చిన్న నోట్ / Loving Note',
                      style: GoogleFonts.notoSansTelugu(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. భోజనం తర్వాత వేసుకో బంగారం, నీళ్లు ఎక్కువగా తాగు ❤️',
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.favorite_outline, color: AppColors.crimsonLove),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pastel Color Theme
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'కార్డ్ రంగు / Card Pastel Color',
                      style: GoogleFonts.notoSansTelugu(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _colorPalette.map((colHex) {
                        final isChosen = _selectedColor == colHex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = colHex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Color(colHex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isChosen ? AppColors.deepPlum : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                if (isChosen)
                                  BoxShadow(
                                    color: Color(colHex).withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: isChosen
                                ? const Icon(Icons.check, size: 18, color: AppColors.deepPlum)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Save Button
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.lavender : AppColors.blushPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                ),
                child: Text(
                  isEdit ? 'మార్పులను భద్రపరుచు / Save Changes' : 'మందును భద్రపరుచు / Save Medicine ❤️',
                  style: GoogleFonts.notoSansTelugu(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.nightIndigo : AppColors.deepPlum,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

