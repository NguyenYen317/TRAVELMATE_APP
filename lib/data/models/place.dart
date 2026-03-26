class Place {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final double? rating;
  final String? openingHours; // Thêm lại trường này để tránh lỗi build
  final List<String> types;
  final double? lat;
  final double? lng;

  Place({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.rating,
    this.openingHours,
    this.types = const [],
    this.lat,
    this.lng,
  });

  static const List<String> _restaurantImages = [
    'https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg?auto=compress&cs=tinysrgb&w=1200',
    'https://images.pexels.com/photos/67468/pexels-photo-67468.jpeg?auto=compress&cs=tinysrgb&w=1200',
    'https://images.pexels.com/photos/696218/pexels-photo-696218.jpeg?auto=compress&cs=tinysrgb&w=1200',
  ];

  static const List<String> _hotelImages = [
    'https://images.pexels.com/photos/164595/pexels-photo-164595.jpeg?auto=compress&cs=tinysrgb&w=1200',
    'https://images.pexels.com/photos/271618/pexels-photo-271618.jpeg?auto=compress&cs=tinysrgb&w=1200',
    'https://images.pexels.com/photos/258154/pexels-photo-258154.jpeg?auto=compress&cs=tinysrgb&w=1200',
  ];

  static const List<String> _tourismImages = [
    'https://images.pexels.com/photos/417074/pexels-photo-417074.jpeg?auto=compress&cs=tinysrgb&w=1200',
    'https://images.pexels.com/photos/1366919/pexels-photo-1366919.jpeg?auto=compress&cs=tinysrgb&w=1200',
    'https://images.pexels.com/photos/21014/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=1200',
  ];

  factory Place.fromJson(Map<String, dynamic> json, {String? categoryHint}) {
    final rawName = json['display_name']?.toString() ?? 'Địa điểm không tên';
    final placeName = rawName.split(',').first;
    final placeType =
        '${json['type'] ?? ''} ${json['class'] ?? ''} ${categoryHint ?? ''}'
            .toLowerCase();

    List<String> imagePool;
    if (placeType.contains('hotel') ||
        placeType.contains('khách sạn') ||
        placeType.contains('resort') ||
        placeType.contains('guest_house')) {
      imagePool = _hotelImages;
    } else if (placeType.contains('restaurant') ||
        placeType.contains('nhà hàng') ||
        placeType.contains('quán ăn') ||
        placeType.contains('food') ||
        placeType.contains('cafe')) {
      imagePool = _restaurantImages;
    } else {
      imagePool = _tourismImages;
    }

    final imageUrl = imagePool[placeName.hashCode.abs() % imagePool.length];

    return Place(
      id: json['place_id'] ?? '',
      name: placeName,
      address: rawName,
      lat: double.tryParse(json['lat']?.toString() ?? ''),
      lng: double.tryParse(json['lon']?.toString() ?? ''),
      types: [json['type'] ?? json['class'] ?? ''],
      rating: 4.0,
      openingHours: null, // LocationIQ không có dữ liệu này nên để null
      imageUrl: imageUrl,
    );
  }
}

class PlacePrediction {
  final String placeId;
  final String description;

  PlacePrediction({required this.placeId, required this.description});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'],
      description: json['display_name'],
    );
  }
}
