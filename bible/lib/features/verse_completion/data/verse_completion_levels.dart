import 'dart:math';

import '../../../core/progress/tiered_levels.dart';
import '../models/verse_completion_item.dart';

/// Verse Completion's take on [TieredLevels]: harder tiers have less familiar
/// verses and longer, closer-sounding answers.
class VerseCompletionLevels {
  VerseCompletionLevels._();

  static const gameModeId = 'verse_completion';

  /// The answer plus enough random distractors for [level], shuffled.
  static List<String> choicesFor(VerseCompletionItem item, int level, Random random) {
    final wrong = [...item.distractors]..shuffle(random);
    return [item.answer, ...wrong.take(TieredLevels.choiceCountFor(level) - 1)]..shuffle(random);
  }
}
