/// Tashkent's 12 administrative districts — mirrors the district names used
/// by `server/lib/src/seed_data.dart` so new projects created through the
/// dropdown line up with the catalogue's existing `district` filter values.
///
/// [kOtherDistrictOption] is a sentinel, not a real district: selecting it in
/// the UI reveals a free-text field for projects outside Tashkent city (e.g.
/// Tashkent Region), matching the "Other Regions" escape hatch already used
/// by [kRegionOptions] in the developer KYC form.
const String kOtherDistrictOption = 'Other';

const List<String> kTashkentDistricts = [
  'Bektemir',
  'Chilanzar',
  'Mirabad',
  'Mirzo Ulugbek',
  'Olmazor',
  'Sergeli',
  'Shayxontohur',
  'Uchtepa',
  'Yakkasaray',
  'Yangihayot',
  'Yashnobod',
  'Yunusabad',
];

const List<String> kDistrictOptions = [
  ...kTashkentDistricts,
  kOtherDistrictOption,
];
