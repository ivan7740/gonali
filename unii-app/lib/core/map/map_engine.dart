enum MapEngine {
  amap,
  osm;

  String get backendValue => switch (this) {
    MapEngine.amap => 'amap',
    MapEngine.osm => 'osm',
  };

  static MapEngine? fromBackend(String? value) => switch (value) {
    'amap' => MapEngine.amap,
    'osm' => MapEngine.osm,
    _ => null,
  };
}
