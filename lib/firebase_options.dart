// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAVPMu0nv3fk0OsmWlVQAYN6L-__K4Z0GA',
    appId: '1:755445236888:web:aca82dc3e1273352f97ced',
    messagingSenderId: '755445236888',
    projectId: 'timretail-457509',
    authDomain: 'timretail-457509.firebaseapp.com',
    storageBucket: 'timretail-457509.firebasestorage.app',
    measurementId: 'G-KM6WJVZ0V8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBfAOTbIbd0yq2i1w2zkQzYTasiF3gUx-Y',
    appId: '1:755445236888:android:f57fdf10d4a45937f97ced',
    messagingSenderId: '755445236888',
    projectId: 'timretail-457509',
    storageBucket: 'timretail-457509.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBTlaOqAPpfxJFUwSFyHE49IDOybe_1X7Q',
    appId: '1:755445236888:ios:8d0f8d054d10b957f97ced',
    messagingSenderId: '755445236888',
    projectId: 'timretail-457509',
    storageBucket: 'timretail-457509.firebasestorage.app',
    androidClientId: '755445236888-44pjvgopqt8uvkpkfnt9ir78vph8hpb1.apps.googleusercontent.com',
    iosBundleId: 'com.example.project',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBTlaOqAPpfxJFUwSFyHE49IDOybe_1X7Q',
    appId: '1:755445236888:ios:8d0f8d054d10b957f97ced',
    messagingSenderId: '755445236888',
    projectId: 'timretail-457509',
    storageBucket: 'timretail-457509.firebasestorage.app',
    androidClientId: '755445236888-44pjvgopqt8uvkpkfnt9ir78vph8hpb1.apps.googleusercontent.com',
    iosBundleId: 'com.example.project',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAVPMu0nv3fk0OsmWlVQAYN6L-__K4Z0GA',
    appId: '1:755445236888:web:08c14f033121036af97ced',
    messagingSenderId: '755445236888',
    projectId: 'timretail-457509',
    authDomain: 'timretail-457509.firebaseapp.com',
    storageBucket: 'timretail-457509.firebasestorage.app',
    measurementId: 'G-6RK80NLTJ1',
  );
}
