import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/place.dart';

class SearchService {
  // LocationIQ API Key
  final String apiKey = "pk.0d81a20b307b8821fcf795d0361e6954";

  // Autocomplete - Gợi ý địa điểm tương tự khi đang gõ
  Future<List<PlacePrediction>> getAutocomplete(String input) async {
    if (input.isEmpty) return [];

    final url = Uri.parse(
        "https://api.locationiq.com/v1/autocomplete?key=$apiKey&q=$input&format=json&accept-language=vi&countrycodes=vn&limit=20");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => PlacePrediction.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  // Lấy chi tiết địa điểm
  Future<Place> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
        "https://us1.locationiq.com/v1/reverse?key=$apiKey&place_id=$placeId&format=json&accept-language=vi");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Place.fromJson(data);
    } else {
      throw Exception("Không tìm thấy thông tin địa điểm");
    }
  }

  // Tìm kiếm theo loại (Nhà hàng, Khách sạn, Điểm du lịch...)
  Future<List<Place>> searchPlacesByType(String type) async {
    // Tăng limit lên 80 để lấy nhiều kết quả hơn theo từ khóa
    final url = Uri.parse(
      "https://us1.locationiq.com/v1/search?key=$apiKey&q=$type&format=json&accept-language=vi&countrycodes=vn&limit=80");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      // LỌC THÔNG MINH:
      // Loại bỏ các kết quả mang tính chất "Vùng/Hành chính" (boundary, administrative, city, suburb)
      // Chỉ giữ lại các địa điểm có class là tourism, historic, leisure, v.v. hoặc các POI cụ thể.
      final List<Place> filteredResults = data
          .where((item) {
            final String placeClass = item['class'] ?? '';
            final String placeType = item['type'] ?? '';

            // Không lấy ranh giới hành chính, không lấy thành phố/quận/phường
            return placeClass != 'boundary' &&
                   placeType != 'administrative';
          })
          .map((item) => Place.fromJson(item, categoryHint: type))
          .toList();

      return filteredResults;
    } else {
      return [];
    }
  }
}
