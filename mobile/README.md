# L&J Doces e Salgados - Flutter

Aplicativo Flutter de autenticação com suporte a Email/Senha e Google OAuth.

## Pré-requisitos

- Flutter 3.0 ou superior
- Dart 3.0 ou superior

## Instalação

1. Instale as dependências:

```bash
flutter pub get
```

2. Configure o arquivo `.env`:

```env
API_BASE_URL=http://localhost:3000
GOOGLE_WEB_CLIENT_ID=seu-google-web-client-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=seu-google-ios-client-id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=seu-google-android-client-id.apps.googleusercontent.com
```

## Executar

```bash
# Desenvolvimento (macOS/Linux/Windows)
flutter run

# Especificar dispositivo
flutter run -d chrome  # Web
flutter run -d emulator-5554  # Android
```

## Configuração do Google OAuth

### Android

1. No `android/app/build.gradle`, configure:

```gradle
android {
    compileSdkVersion 33

    defaultConfig {
        applicationId "br.com.lejdoces.app"
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

2. Adicione o SHA-1 no Google Cloud Console

### iOS

1. Configure o URL scheme no `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>googlechromestealth</string>
  <string>googlechrome</string>
</array>
```

## Estrutura do Projeto

```
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   └── auth_response.dart
├── screens/
│   ├── signin_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   └── profile_screen.dart
├── providers/
│   └── auth_provider.dart
├── services/
│   ├── api_service.dart
│   └── storage_service.dart
└── widgets/
    └── custom_text_field.dart
```

## Funcionalidades

- ✅ Registro com Email e Senha
- ✅ Login com Email e Senha
- ✅ Autenticação com Google
- ✅ Perfil do usuário
- ✅ Edição de perfil
- ✅ Logout
- ✅ Armazenamento local de token
- ✅ Autenticação persistente

## Comunicação com API

A API é acessada através da variável de ambiente `API_BASE_URL`.

Endpoints utilizados:
- `POST /auth/signup` - Registrar
- `POST /auth/signin` - Login
- `GET /auth/google` - Google OAuth
- `GET /auth/profile` - Obter perfil
- `POST /auth/profile/update` - Atualizar perfil
