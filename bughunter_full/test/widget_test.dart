import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bughunter/data/content_repository.dart';
import 'package:bughunter/main.dart';
import 'package:bughunter/models/content.dart';
import 'package:bughunter/state/progress_state.dart';

ContentData loadContent() {
  return ContentRepository.parse(File('assets/content/content.json').readAsStringSync());
}

void main() {
  test('очки: база по сложности, каждая ошибка снимает 5, минимум 5', () {
    expect(ProgressState.calcXp(2, 0), 30);
    expect(ProgressState.calcXp(1, 2), 10);
    expect(ProgressState.calcXp(0, 0), 10);
    expect(ProgressState.calcXp(0, 5), 5);
  });

  test('контент: есть языки, уровни и задачи', () {
    final data = loadContent();
    expect(data.languages.isNotEmpty, true);
    final ids = <String>{};
    for (final lang in data.languages) {
      expect(lang.levels.isNotEmpty, true, reason: lang.id);
      for (final lv in lang.levels) {
        expect(lv.theory.isNotEmpty, true, reason: lv.id);
        expect(lv.tasks.isNotEmpty, true, reason: lv.id);
        for (final t in lv.tasks) {
          expect(ids.add(t.id), true, reason: 'повтор id ${t.id}');
          expect(t.hint.isNotEmpty, true, reason: t.id);
          expect(t.explanation.isNotEmpty, true, reason: t.id);
          if (t.type == TaskType.find) {
            expect(t.bugLine >= 0 && t.bugLine < t.lines.length, true, reason: t.id);
            expect(t.fix.trim() != t.buggyLine.trim(), true, reason: t.id);
          } else {
            expect(t.answer >= 0 && t.answer < t.options.length, true, reason: t.id);
          }
        }
      }
    }
  });

  testWidgets('запуск: заставка, затем экран входа', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(BugHunterApp(prefs: prefs, content: loadContent()));
    expect(find.text('BugHunter'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Войти'), findsWidgets);
    expect(find.text('Забыли пароль?'), findsOneWidget);
  });
}
