import 'package:flutter_test/flutter_test.dart';
import 'package:personality_ai/core/services/recurring_task_service.dart';

void main() {
  group('RecurrencePattern', () {
    test('toJson returns correct string for daily', () {
      expect(RecurrencePattern.daily.toJson(), 'daily');
    });

    test('toJson returns correct string for weekly', () {
      expect(RecurrencePattern.weekly.toJson(), 'weekly');
    });

    test('toJson returns correct string for monthly', () {
      expect(RecurrencePattern.monthly.toJson(), 'monthly');
    });

    test('toJson returns correct string for custom', () {
      expect(RecurrencePattern.custom.toJson(), 'custom');
    });

    test('fromJson parses daily correctly', () {
      expect(RecurrencePattern.fromJson('daily'), RecurrencePattern.daily);
    });

    test('fromJson parses weekly correctly', () {
      expect(RecurrencePattern.fromJson('weekly'), RecurrencePattern.weekly);
    });

    test('fromJson parses monthly correctly', () {
      expect(RecurrencePattern.fromJson('monthly'), RecurrencePattern.monthly);
    });

    test('fromJson parses custom correctly', () {
      expect(RecurrencePattern.fromJson('custom'), RecurrencePattern.custom);
    });

    test('fromJson throws on invalid input', () {
      expect(
        () => RecurrencePattern.fromJson('invalid'),
        throwsA(isA<StateError>()),
      );
    });

    test('roundtrip serialization works for all values', () {
      for (final pattern in RecurrencePattern.values) {
        final json = pattern.toJson();
        final restored = RecurrencePattern.fromJson(json);
        expect(restored, pattern);
      }
    });
  });
}
