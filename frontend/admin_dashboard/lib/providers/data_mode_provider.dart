import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Demo data until admin signs in with live backend credentials.
enum DataMode { demo, live }

/// Always start in demo so the dashboard never blocks on an empty database.
final dataModeProvider = StateProvider<DataMode>((ref) => DataMode.demo);

final usingDemoDataProvider = Provider<bool>((ref) {
  return ref.watch(dataModeProvider) == DataMode.demo;
});
