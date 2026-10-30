import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/telugu_quote.dart';
import 'storage_service.dart';

class QuoteService {
  static final QuoteService _instance = QuoteService._internal();
  factory QuoteService() => _instance;
  QuoteService._internal();

  final List<TeluguQuote> _defaultQuotes = [];
  bool _isLoaded = false;
  final Random _random = Random();

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/quotes.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      _defaultQuotes.clear();
      for (final item in list) {
        _defaultQuotes.add(TeluguQuote.fromJson(item));
      }
      _isLoaded = true;
    } catch (e) {
      // Fallback quotes (Telugu written in English letters so she can read easily)
      _defaultQuotes.addAll([
        TeluguQuote(
          id: 1,
          telugu: "Nee arogyame mana baby arogyam. Mandulu vesuko bangaram ❤️",
          english: "Your health is our baby's health. Take your medicines, bangaram ❤️",
        ),
        TeluguQuote(
          id: 2,
          telugu: "Mandulu marchipothe mana baby ki ibbandi avthundi. Ippude vesuko 🙏",
          english: "If you forget medicines it troubles our baby. Please take it now 🙏",
        ),
        TeluguQuote(
          id: 3,
          telugu: "Nuvvu baagunte nenu baaguntanu. Tablet vesukunnava? ❤️",
          english: "I am fine only if you are fine. Did you take your tablet?",
        ),
        TeluguQuote(
          id: 4,
          telugu: "Naa pranam nuvve, mana baby kooda. Mandu time ayindi! 🍼",
          english: "You are my life, and our baby too. It's medicine time!",
        ),
        TeluguQuote(
          id: 5,
          telugu: "Okka tablet... mana baby ki oka pedda gift 🍼",
          english: "Just one tablet... is a big gift for our baby 🍼",
        ),
        TeluguQuote(
          id: 6,
          telugu: "Naa kosam kaadu, mana baby kosam vesuko chinna 💕",
          english: "Not for me, take it for our baby chinna 💕",
        ),
        TeluguQuote(
          id: 7,
          telugu: "Ippude vesuko, tharvatha naaku message cheyyi ❤️",
          english: "Take it right now, and message me after ❤️",
        ),
      ]);
      _isLoaded = true;
    }
  }

  /// Get all quotes including custom ones from Storage
  List<TeluguQuote> getAllQuotes() {
    final custom = StorageService().customQuotes;
    return [..._defaultQuotes, ...custom];
  }

  /// Get random quote
  TeluguQuote getRandomQuote() {
    final all = getAllQuotes();
    if (all.isEmpty) {
      return TeluguQuote(
        id: 0,
        telugu: "Nee arogyame mana baby arogyam. Mandulu vesuko bangaram ❤️",
        english: "Your health is our baby's health. Take your medicines, bangaram ❤️",
      );
    }
    return all[_random.nextInt(all.length)];
  }
}
