/// AgriSmartAI :: Rotating farming tips for New Bataan rice farmers.
/// OBJECTIVE 3: practical fertilizer + crop-care guidance inside the app.
class FarmingTips {
  FarmingTips._();

  static const List<String> tips = [
    'Inspect your rice leaves weekly - early detection means easier treatment.',
    'Apply balanced 90-60-60 NPK fertilizer based on a DA soil test, not by guess.',
    'Avoid too much nitrogen; it makes plants weak against blight and tungro.',
    'Use certified, disease-resistant seeds from DA-New Bataan each season.',
    'Drain your field properly to slow the spread of bacterial leaf blight.',
    'Synchronize planting with neighbors to reduce tungro-carrying leafhoppers.',
    'Take photos in good daylight and fill the frame with a single leaf for best results.',
    'Keep the area clean - remove infected stubble after harvest.',
    'Report any sudden yellowing or wilting to the Municipal Agriculture Office.',
    'Split nitrogen fertilizer into 3 applications for healthier, stronger plants.',
  ];

  /// A tip chosen by day-of-year so it stays stable through the day.
  static String today() {
    final day = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return tips[day % tips.length];
  }
}
