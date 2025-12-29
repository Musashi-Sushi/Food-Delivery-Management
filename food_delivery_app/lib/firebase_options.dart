import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA1KheuCOMdkw11Vpa48hzGCfsxYOwBW-s',
    appId: '1:620836965590:android:88da402cfe530256df0d77',
    messagingSenderId: '620836965590',
    projectId: 'food-delivery-app-69efd',
    storageBucket: 'food-delivery-app-69efd.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB8dKjQj5rYCFQ6meaF5yuzAEmf-obLDCY',
    appId: '1:620836965590:web:7ef506e8d747a794df0d77',
    messagingSenderId: '620836965590',
    projectId: 'food-delivery-app-69efd',
    authDomain: 'food-delivery-app-69efd.firebaseapp.com',
    storageBucket: 'food-delivery-app-69efd.firebasestorage.app',
    measurementId: 'G-33TWPNJL5Y',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB8dKjQj5rYCFQ6meaF5yuzAEmf-obLDCY',
    appId: '1:620836965590:web:7ef506e8d747a794df0d77',
    messagingSenderId: '620836965590',
    projectId: 'food-delivery-app-69efd',
    authDomain: 'food-delivery-app-69efd.firebaseapp.com',
    storageBucket: 'food-delivery-app-69efd.firebasestorage.app',
    measurementId: 'G-33TWPNJL5Y',
  );
}
