import 'package:unii_app/core/map/amap_adapter.dart';
import 'package:unii_app/core/map/map_adapter.dart';
import 'package:unii_app/core/map/map_engine.dart';
import 'package:unii_app/core/map/osm_adapter.dart';

abstract class MapFactory {
  MapFactory._();

  static MapAdapter create(MapEngine engine) => switch (engine) {
    MapEngine.amap => const AmapAdapter(),
    MapEngine.osm => const OsmAdapter(),
  };
}
