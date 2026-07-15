/// Maps a unit's [rooms]/[layout] to a bundled local floor-plan SVG asset.
///
/// Apartments carry [rooms] (1-4); offices carry a [layout] string instead.
/// Any combination that doesn't match a dedicated diagram (including both
/// being null) falls back to the generic outline so the caller always has
/// something sensible to render.
const String fallbackFloorPlanAsset = 'assets/floorplans/fallback.svg';

String? floorPlanAssetFor({int? rooms, String? layout}) {
  switch (rooms) {
    case 1:
      return 'assets/floorplans/rooms_1.svg';
    case 2:
      return 'assets/floorplans/rooms_2.svg';
    case 3:
      return 'assets/floorplans/rooms_3.svg';
    case 4:
      return 'assets/floorplans/rooms_4.svg';
  }

  switch (layout) {
    case 'Open plan':
      return 'assets/floorplans/office_open_plan.svg';
    case 'Cabinet layout':
      return 'assets/floorplans/office_cabinet_layout.svg';
    case 'Corner suite':
      return 'assets/floorplans/office_corner_suite.svg';
  }

  return fallbackFloorPlanAsset;
}
