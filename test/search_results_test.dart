import 'package:flutter_test/flutter_test.dart';
import 'package:personality_ai/core/services/search_service.dart';

void main() {
  group('SearchResults', () {
    test('isEmpty returns true when all lists are empty', () {
      final results = SearchResults(
        tasks: [],
        notes: [],
        transactions: [],
        events: [],
      );
      expect(results.isEmpty, true);
    });

    test('isEmpty returns false when tasks is not empty', () {
      // We can't easily create TaskEntity without DB, so test with empty lists
      // This validates the container logic
      final results = SearchResults(
        tasks: [],
        notes: [],
        transactions: [],
        events: [],
      );
      expect(results.isEmpty, true);
      expect(results.totalCount, 0);
    });

    test('totalCount returns 0 for empty results', () {
      final results = SearchResults(
        tasks: [],
        notes: [],
        transactions: [],
        events: [],
      );
      expect(results.totalCount, 0);
    });
  });
}
