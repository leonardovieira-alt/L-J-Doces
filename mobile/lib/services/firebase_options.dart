import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
      // Cole os valores do Firebase Console aqui:
      apiKey: "AIzaSyBtZD2PLK9H98LLvvYpcYTxVq_wP-7ufDw",
      authDomain: "projeto-2026-e4ed0.firebaseapp.com",
      databaseURL: "https://projeto-2026-e4ed0-default-rtdb.firebaseio.com",
      projectId: "projeto-2026-e4ed0",
      storageBucket: "projeto-2026-e4ed0.firebasestorage.app",
      messagingSenderId: "634473768433",
      appId: "1:634473768433:web:eabd00a09b4c8984015050",
      measurementId: "G-V9MG94P0BH");
}
