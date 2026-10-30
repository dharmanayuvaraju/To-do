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
      // Fallback 7 quotes in case asset loading fails
      _defaultQuotes.addAll([
        TeluguQuote(
          id: 1,
          telugu: "నీ ఆరోగ్యమే మన బేబీ ఆరోగ్యం. మందులు వేసుకో బంగారం ❤️",
          english: "Your health is our baby's health. Take your medicines, bangaram ❤️",
        ),
        TeluguQuote(
          id: 2,
          telugu: "మందులు మర్చిపోతే మన బేబీకి ఇబ్బంది అవుతుంది. ఇప్పుడే వేసుకో 🙏",
          english: "If you forget medicines it troubles our baby. Please take it now 🙏",
        ),
        TeluguQuote(
          id: 3,
          telugu: "నువ్వు బాగుంటేనే నేను బాగుంటాను. టాబ్లెట్ వేసుకున్నావా?",
          english: "I am fine only if you are fine. Did you take your tablet?",
        ),
        TeluguQuote(
          id: 4,
          telugu: "నా ప్రాణం నువ్వే, మన బేబీ కూడా. మందు టైమ్ అయింది!",
          english: "You are my life, and our baby too. It's medicine time!",
        ),
        TeluguQuote(
          id: 5,
          telugu: "ఒక్క టాబ్లెట్... మన బేబీకి ఒక పెద్ద బహుమతి 🍼",
          english: "Just one tablet... is a big gift for our baby 🍼",
        ),
        TeluguQuote(
          id: 6,
          telugu: "నా కోసం కాదు, మన బేబీ కోసం వేసుకో చిన్నా 💕",
          english: "Not for me, take it for our baby chinna 💕",
        ),
        TeluguQuote(
          id: 7,
          telugu: "ఇప్పుడే వేసుకో, తర్వాత నాకు మెసేజ్ చెయ్యి ❤️",
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
        telugu: "నీ ఆరోగ్యమే మన బేబీ ఆరోగ్యం. మందులు వేసుకో బంగారం ❤️",
        english: "Your health is our baby's health. Take your medicines, bangaram ❤️",
      );
    }
    return all[_random.nextInt(all.length)];
  }
}
