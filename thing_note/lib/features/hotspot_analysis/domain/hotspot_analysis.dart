/// Hotspot analysis result
class HotspotAnalysis {
  final DateTime analyzedAt;
  final List<HotspotLocation> locations;
  final List<HotspotTimeSlot> timeSlots;
  final Map<String, int> tagDistribution;
  final String? dominantPattern;

  HotspotAnalysis({
    required this.analyzedAt,
    required this.locations,
    required this.timeSlots,
    required this.tagDistribution,
    this.dominantPattern,
  });
}

class HotspotLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final int recordCount;
  final double radius; // km

  HotspotLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.recordCount,
    this.radius = 0.5,
  });
}

class HotspotTimeSlot {
  final int hour;
  final int recordCount;
  final double avgDuration;
  final List<String> commonThingNames;

  HotspotTimeSlot({
    required this.hour,
    required this.recordCount,
    required this.avgDuration,
    required this.commonThingNames,
  });
}