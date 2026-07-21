import 'dart:convert';
import 'package:flutter/services.dart';

class ReflectionService {
  ReflectionService._();
  static final ReflectionService instance = ReflectionService._();

  final Map<String, List<String>> _mem = {};

  Future<List<String>> load(String book, int chapter) async {
    final folder = book.toLowerCase().replaceAll(' ', '').replaceAll("'", '');
    final key = '$folder:$chapter';
    if (_mem.containsKey(key)) return _mem[key]!;

    final path = 'assets/data/reflections/$folder/$chapter.json';
    final raw = await rootBundle.loadString(path);
    final list = (json.decode(raw) as List).cast<String>();
    _mem[key] = list;
    return list;
  }

  void clearCache() => _mem.clear();
}
