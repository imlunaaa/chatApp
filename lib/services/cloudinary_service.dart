import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "jerp4v1a";
  static const String uploadPreset = "ml_default";

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);
      return data["secure_url"] as String;
    } else {
      final err = await response.stream.bytesToString();
      print("Cloudinary upload failed: $err");
      return null;
    }
  }
}
