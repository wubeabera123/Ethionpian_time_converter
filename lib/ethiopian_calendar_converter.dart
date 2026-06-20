class EthiopianDate {
  final int year;
  final int month;
  final int day;

  EthiopianDate(this.year, this.month, this.day);

  @override
  String toString() {
    return '$day/$month/$year';
  }

  String get monthName {
    const months = [
      'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yakatit',
      'Magabit', 'Miyazya', 'Gunbot', 'Sane', 'Hamle', 'Nehasie', 'Pagume'
    ];
    return months[month - 1];
  }
}

class EthiopianCalendarConverter {
  /// Simple Gregorian to Ethiopian conversion
  static EthiopianDate convertToEthiopian(DateTime date) {
    // This is a simplified conversion logic.
    // For more accuracy, a more complex Julian Day based algorithm should be used.
    int year = date.year - 8;
    int month, day;

    // The Ethiopian New Year is usually Sept 11
    DateTime newYear = DateTime(date.year, 9, 11);

    // Check if it's a leap year in Gregorian to adjust Sept 12
    // Actually, Ethiopian leap year cycle is every 4 years.
    // 2015 ET was leap year (Pagume 6).

    if (date.isBefore(newYear)) {
      year = date.year - 8;
      // Calculate days since last Ethiopian New Year (Sept 11 of previous year)
      DateTime prevNewYear = DateTime(date.year - 1, 9, 11);
      int diff = date.difference(prevNewYear).inDays;
      month = (diff ~/ 30) + 1;
      day = (diff % 30) + 1;
    } else {
      year = date.year - 7;
      int diff = date.difference(newYear).inDays;
      month = (diff ~/ 30) + 1;
      day = (diff % 30) + 1;
    }

    return EthiopianDate(year, month, day);
  }

  /// Convert 24-hour clock to Ethiopian clock
  /// Ethiopian day starts at 6:00 AM (0:00 Ethiopian)
  static String convertToEthiopianTime(DateTime date) {
    int hour = date.hour;
    int minute = date.minute;

    int etHour;
    String period;

    if (hour >= 6 && hour < 18) {
      // Daytime: 6 AM to 6 PM Gregorian is 0 to 12 Ethiopian Day
      etHour = hour - 6;
      period = 'Day';
    } else {
      // Nighttime
      if (hour >= 18) {
        etHour = hour - 18;
      } else {
        etHour = hour + 6;
      }
      period = 'Night';
    }

    String hourStr = etHour == 0 ? '12' : etHour.toString();
    String minStr = minute.toString().padLeft(2, '0');

    return '$hourStr:$minStr $period';
  }
}
