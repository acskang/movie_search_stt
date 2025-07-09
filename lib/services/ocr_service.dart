// lib/services/ocr_service.dart
// OCR 기능은 임시로 제거되었습니다.
// Google ML Kit 호환성 문제로 인해 향후 다른 패키지로 대체 예정

class OcrService {
  // 빈 클래스 - 컴파일 오류 방지용

  bool get isProcessing => false;

  // 콜백 함수들 (빈 구현)
  Function(String)? onTextRecognized;
  Function(String, bool)? onError;
  Function(double)? onProgress;

  // 빈 메서드들
  Future<String?> recognizeTextFromCamera() async {
    onError?.call('OCR 기능이 일시적으로 비활성화되었습니다.', true);
    return null;
  }

  Future<String?> recognizeTextFromGallery() async {
    onError?.call('OCR 기능이 일시적으로 비활성화되었습니다.', true);
    return null;
  }

  void dispose() {
    // 빈 구현
  }
}
