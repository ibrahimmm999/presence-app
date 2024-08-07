import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as myHttp;
//untuk fetch data titik koordinat
class PresensiUtil {
  static List<double> targetLatitudes = [];
  static List<double> targetLongitudes = [];

  static Future<void> fetchTargetCoordinates() async {
    var response = await myHttp.get(
        Uri.parse('https://datatech.co.id/indexLaravel.php/get-coordinates'));
    var data = json.decode(response.body);
    print(data);
    if (data['success']) {
      targetLatitudes = List<double>.from(
          data['data'].map((item) => double.parse(item['latitude'])));
      targetLongitudes = List<double>.from(
          data['data'].map((item) => double.parse(item['longitude'])));
    } else {
      throw Exception('Failed to load target coordinates');
    }
  }
//untuk menyimpan absensi ketika titik koordinat sudah diketahui dan batasan jarak untuk bisa melakukan absen
  static Future savePresensi(
      double latitude, double longitude, String token) async {
    if (targetLatitudes.isEmpty || targetLongitudes.isEmpty) {
      await fetchTargetCoordinates();
    }
    double maxDistance = 0.5; // Jarak maksimum yang diizinkan
    double nearestDistance = double.infinity;
    int nearestIndex = -1; // Jarak maksimum yang diizinkan
    // Menghitung jarak antara lokasi saat ini dan lokasi yang diinginkan
    print(targetLatitudes);
    print(targetLongitudes);

    for (int i = 0; i < targetLatitudes.length; i++) {
      double targetLatitude = targetLatitudes[i];
      double targetLongitude = targetLongitudes[i];

      double distance = calculateDistance(
          latitude, longitude, targetLatitude, targetLongitude);

      if (distance <= maxDistance && distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }
//intinya ketika user melakukan tapping absen aplikasi akan mengecek titik koordinat user, jika user berada di titik koordinat yang benar maka absen akan berhasil dan akan disimpan
    if (nearestIndex != -1) {
      Map<String, String> body = {
        "latitude": latitude.toString(),
        "longitude": longitude.toString()
      };
      Map<String, String> headers = {'Authorization': 'Bearer $token'};

      var response = await myHttp.post(
          Uri.parse(
              "https://datatech.co.id/indexLaravel.php/api/save-presensi"),
          body: body,
          headers: headers);
      return json.decode(response.body);
    } else {
      return {
        'success': false,
        'message': 'Anda tidak berada di lokasi yang diizinkan untuk absen.' //jika tidak sesuai maka akan muncul pesan
      };
    }
  }
//untuk menghitung jarak
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radiusEarth = 6371.0; // Radius Bumi dalam kilometer

    double dLat = degreesToRadians(lat2 - lat1);
    double dLon = degreesToRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(lat1)) *
            cos(degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = radiusEarth * c;

    return distance;
  }

  static double degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}
