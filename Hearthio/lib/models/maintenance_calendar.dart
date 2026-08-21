/// Maintenance dates are civil calendar dates, not elapsed 24-hour windows.
/// Reading the components directly prevents a stored date from moving after a
/// device-zone change.
DateTime maintenanceDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Adds calendar days through the date constructor instead of Duration, so a
/// daylight-saving transition cannot turn one maintenance day into 23 or 25
/// elapsed hours.
DateTime addMaintenanceDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

int maintenanceDayDifference(DateTime later, DateTime earlier) {
  final laterUtc = DateTime.utc(later.year, later.month, later.day);
  final earlierUtc = DateTime.utc(earlier.year, earlier.month, earlier.day);
  return laterUtc.difference(earlierUtc).inDays;
}
