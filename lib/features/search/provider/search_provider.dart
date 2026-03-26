import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../search_service.dart';
import '../../../data/models/place.dart';

class SearchProvider extends ChangeNotifier {
  final SearchService _searchService = SearchService();
  
  List<PlacePrediction> _predictions = [];
  List<PlacePrediction> get predictions => _predictions;

  List<Place> _searchResults = [];
  List<Place> get searchResults => _searchResults;

  List<Place> _nearbyPlaces = [];
  List<Place> get nearbyPlaces => _nearbyPlaces;

  List<String> _favoritePlaceIds = [];
  List<String> get favoritePlaceIds => _favoritePlaceIds;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SearchProvider() {
    _loadFavorites();
    fetchNearbyPlaces();
  }

  List<Place> _mergeUniquePlaces(List<List<Place>> groups) {
    final Map<String, Place> unique = {};

    for (final group in groups) {
      for (final place in group) {
        final key = place.id.isNotEmpty
            ? place.id
            : '${place.name.toLowerCase()}_${place.address.toLowerCase()}';
        unique[key] = place;
      }
    }

    return unique.values.toList();
  }

  List<String> _buildCategoryQueries(String category, String keyword) {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) return [category];

    return [
      '$category ở $trimmedKeyword',
      '$category tại $trimmedKeyword',
    ];
  }

  Future<void> fetchNearbyPlaces() async {
    _isLoading = true;
    notifyListeners();
    try {
      _nearbyPlaces = await _searchService.searchPlacesByType('tourist_attraction');
    } catch (e) {
      print("Lỗi tải địa điểm gần bạn: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchAutocomplete(String query) async {
    if (query.isEmpty) {
      _predictions = [];
      _searchResults = []; // Xóa kết quả cũ khi xóa từ khóa
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final restaurantQueries = _buildCategoryQueries('nhà hàng', query);
      final hotelQueries = _buildCategoryQueries('khách sạn', query);
      final tourismQueries = _buildCategoryQueries('điểm du lịch', query);

      final results = await Future.wait([
        _searchService.getAutocomplete(query),
        _searchService.searchPlacesByType(query),
        _searchService.searchPlacesByType(restaurantQueries[0]),
        _searchService.searchPlacesByType(restaurantQueries[1]),
        _searchService.searchPlacesByType(hotelQueries[0]),
        _searchService.searchPlacesByType(hotelQueries[1]),
        _searchService.searchPlacesByType(tourismQueries[0]),
        _searchService.searchPlacesByType(tourismQueries[1]),
      ]);

      _predictions = results[0] as List<PlacePrediction>;
      _searchResults = _mergeUniquePlaces([
        results[1] as List<Place>,
        results[2] as List<Place>,
        results[3] as List<Place>,
        results[4] as List<Place>,
        results[5] as List<Place>,
        results[6] as List<Place>,
        results[7] as List<Place>,
      ]);
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterPlaces(String type, {String? query}) async {
    _isLoading = true;
    _predictions = []; // Ẩn gợi ý autocomplete
    _searchResults = []; // XÓA KẾT QUẢ CŨ TRƯỚC KHI TẢI KẾT QUẢ BỘ LỌC MỚI
    notifyListeners();
    try {
      final queries = _buildCategoryQueries(type, query ?? '');
      final resultGroups = await Future.wait(
        queries.map((item) => _searchService.searchPlacesByType(item)),
      );
      _searchResults = _mergeUniquePlaces(resultGroups);
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Place?> getDetails(String placeId) async {
    try {
      return await _searchService.getPlaceDetails(placeId);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoritePlaceIds = prefs.getStringList('favorite_places') ?? [];
    notifyListeners();
  }

  Future<void> toggleFavorite(String placeId) async {
    if (_favoritePlaceIds.contains(placeId)) {
      _favoritePlaceIds.remove(placeId);
    } else {
      _favoritePlaceIds.add(placeId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_places', _favoritePlaceIds);
    notifyListeners();
  }

  bool isFavorite(String placeId) => _favoritePlaceIds.contains(placeId);
}
