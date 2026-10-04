import 'package:bible_gamehive/features/compete/data/compete_repository.dart';
import 'package:bible_gamehive/features/compete/models/compete_models.dart';
import 'package:bible_gamehive/features/trivia/providers/trivia_session_provider.dart';
import 'package:bible_gamehive/core/models/difficulty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompeteRepository.todayKey', () {
    test('uses the UTC date so every timezone shares one daily challenge', () {
      // 23:30 on Oct 2 in UTC-5 is already Oct 3 in UTC.
      final lateEvening = DateTime.parse('2026-10-02T23:30:00-05:00');
      expect(CompeteRepository.todayKey(lateEvening), '2026-10-03');
    });

    test('normalizes typed codes', () {
      expect(CompeteRepository.normalizeCode(' ab-c2 34 '), 'ABC234');
    });
  });

  test('daily seed is derived from the day key', () {
    expect(const DailyCompetition('2026-10-03').seed, 20261003);
  });

  test('seeded trivia rounds give every player the same 10 questions in the same order', () async {
    Future<List<String>> draw(int seed) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final config = TriviaConfig(category: 'All', difficulty: Difficulty.adult, kidMode: true, seed: seed);
      container.listen(triviaSessionProvider(config), (_, _) {});
      while (container.read(triviaSessionProvider(config)).status == TriviaStatus.loading) {
        await Future<void>.delayed(Duration.zero);
      }
      return container.read(triviaSessionProvider(config)).questions.map((q) => q.id).toList();
    }

    final first = await draw(20261003);
    final second = await draw(20261003);
    final otherDay = await draw(20261004);

    expect(first, hasLength(TriviaConfig.seededQuestionCount));
    expect(second, first);
    expect(otherDay, isNot(first));
  });
}
