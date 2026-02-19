import 'package:flutter_test/flutter_test.dart';
import 'package:solotasks/core/logic/holiday_ops.dart';
import 'package:solotasks/core/models/app_models.dart';

void main() {
  test('toggle holiday type adds then removes', () {
    final date = DateTime(2026, 4, 14);
    final once = toggleHolidayType({}, date, HolidayType.public);
    expect(once[date], contains(HolidayType.public));

    final twice = toggleHolidayType(once, date, HolidayType.public);
    expect(twice[date], isNull);
  });

  test('clear type for year removes target type only', () {
    final source = {
      DateTime(2026, 1, 1): [HolidayType.public, HolidayType.bank],
      DateTime(2025, 1, 1): [HolidayType.public],
    };

    final cleared = clearTypeForYear(source, 2026, HolidayType.public);
    expect(cleared[DateTime(2026, 1, 1)], [HolidayType.bank]);
    expect(cleared[DateTime(2025, 1, 1)], [HolidayType.public]);
  });

  test('copy previous year clones selected type', () {
    final source = {
      DateTime(2025, 4, 14): [HolidayType.public],
    };

    final copied = copyTypeFromPreviousYear(source, 2026, HolidayType.public);
    expect(copied[DateTime(2026, 4, 14)], [HolidayType.public]);
  });
}
