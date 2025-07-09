// FlutterFire CLI에 의해 생성된 파일입니다.
// ignore_for_file: type=lint

// FirebaseOptions 클래스를 사용하기 위해 Firebase core 패키지를 가져옵니다.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
// 플랫폼별 상수 및 확인을 위해 foundation 패키지를 가져옵니다.
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Flutter 앱에서 Firebase를 초기화하기 위한 기본 [FirebaseOptions] 설정 클래스입니다.
///
/// 이 클래스는 플랫폼별 Firebase 설정 옵션을 제공합니다.
/// 사용 예시:
/// ```dart
/// import 'firebase_options.dart';
/// // 적절한 플랫폼 옵션으로 Firebase를 초기화합니다.
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  /// 현재 플랫폼에 맞는 Firebase 설정을 반환하는 정적 getter입니다.
  static FirebaseOptions get currentPlatform {
    // 웹 플랫폼인지 확인합니다.
    if (kIsWeb) {
      // 웹 플랫폼의 경우, 설정이 구성되지 않았음을 알리는 예외를 발생시킵니다.
      throw UnsupportedError(
        '웹용 DefaultFirebaseOptions가 구성되지 않았습니다. '
            'FlutterFire CLI를 다시 실행하여 재구성할 수 있습니다.',
      );
    }
    // 현재 플랫폼에 따라 적절한 FirebaseOptions를 반환합니다.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      // Android 플랫폼의 경우, android 설정을 반환합니다.
        return android;
      case TargetPlatform.iOS:
      // iOS 플랫폼의 경우, ios 설정을 반환합니다.
        return ios;
      case TargetPlatform.macOS:
      // macOS 플랫폼의 경우, 설정이 구성되지 않았음을 알리는 예외를 발생시킵니다.
        throw UnsupportedError(
          'macOS용 DefaultFirebaseOptions가 구성되지 않았습니다. '
              'FlutterFire CLI를 다시 실행하여 재구성할 수 있습니다.',
        );
      case TargetPlatform.windows:
      // Windows 플랫폼의 경우, 설정이 구성되지 않았음을 알리는 예외를 발생시킵니다.
        throw UnsupportedError(
          'Windows용 DefaultFirebaseOptions가 구성되지 않았습니다. '
              'FlutterFire CLI를 다시 실행하여 재구성할 수 있습니다.',
        );
      case TargetPlatform.linux:
      // Linux 플랫폼의 경우, 설정이 구성되지 않았음을 알리는 예외를 발생시킵니다.
        throw UnsupportedError(
          'Linux용 DefaultFirebaseOptions가 구성되지 않았습니다. '
              'FlutterFire CLI를 다시 실행하여 재구성할 수 있습니다.',
        );
      default:
      // 지원되지 않는 플랫폼의 경우 예외를 발생시킵니다.
        throw UnsupportedError(
          '이 플랫폼에서는 DefaultFirebaseOptions가 지원되지 않습니다.',
        );
    }
  }

  /// Android 플랫폼을 위한 Firebase 설정 옵션입니다.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC2nxRbsrzc8I0ecfvL0fWTFpqZvdPg2m0', // Firebase API 키
    appId: '1:518285855054:android:c6df981b8c102483d5b61f', // Android 앱 ID
    messagingSenderId: '518285855054', // 메시징 발신자 ID
    projectId: 'neverland-ab55b', // Firebase 프로젝트 ID
    storageBucket: 'neverland-ab55b.firebasestorage.app', // Firebase 스토리지 버킷
  );

  /// iOS 플랫폼을 위한 Firebase 설정 옵션입니다.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0cFCEyCFSTBtYgnveU8oGeYJHowSJZhs', // Firebase API 키
    appId: '1:518285855054:ios:f826fe32bbd5b270d5b61f', // iOS 앱 ID
    messagingSenderId: '518285855054', // 메시징 발신자 ID
    projectId: 'neverland-ab55b', // Firebase 프로젝트 ID
    storageBucket: 'neverland-ab55b.firebasestorage.app', // Firebase 스토리지 버킷
    androidClientId: '518285855054-rjtgih49d2jh6uvf71j7g91339cs9n0v.apps.googleusercontent.com', // Android 클라이언트 ID
    iosClientId: '518285855054-j3pedjgjstjjgubt1hg8u38hcs13uea2.apps.googleusercontent.com', // iOS 클라이언트 ID
    iosBundleId: 'com.example.neverlandFlutter', // iOS 앱 번들 ID
  );
}