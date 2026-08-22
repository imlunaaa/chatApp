class CloudinaryUtils {
  /// Inserts a transformation string into a Cloudinary secure_url.
  static String transform(String originalUrl, String transformation) {
    const marker = "/upload/";
    final index = originalUrl.indexOf(marker);
    if (index == -1) return originalUrl; // not a Cloudinary URL, return as-is

    final insertAt = index + marker.length;
    return originalUrl.substring(0, insertAt) +
        transformation +
        "/" +
        originalUrl.substring(insertAt);
  }

  static String thumbnail(String originalUrl) {
    return transform(originalUrl, "w_400,q_auto,f_auto,c_limit");
  }

  static String fullSize(String originalUrl, {required String heroTag}) {
    return transform(originalUrl, "q_auto,f_auto");
  }
}
