# 📦✨ downloader_manager

`downloader_manager` es una poderosa librería para Dart que facilita la gestión avanzada de descargas de archivos desde internet. Utiliza rangos de descarga (descarga por partes) y aprovecha isolates para realizar descargas en paralelo sin bloquear la interfaz de usuario ni el hilo principal de tu aplicación. Es ideal para aplicaciones que requieren descargas concurrentes, seguimiento de progreso en tiempo real y control total sobre cada tarea de descarga.

Con `downloader_manager` puedes:

- 📥 Descargar múltiples archivos simultáneamente sin afectar el rendimiento de tu app.
- ⏸️ Pausar y ▶️ reanudar descargas en cualquier momento.
- 🛑 Detener, cancelar y eliminar tareas de descarga de forma segura.
- 📊 Monitorear el progreso y estado de cada descarga con streams reactivos.
- 🏷️ Identificar y controlar descargas mediante tokens únicos.
- ⚡ Descargar archivos por rangos (descarga por partes) para mayor eficiencia.
- 🧩 Gestionar errores y eventos en tiempo real para una experiencia robusta.
- 🧵 Aprovechar isolates para descargas en paralelo y mayor rendimiento.
- 🧹 Liberar recursos y cerrar todos los isolates fácilmente.

---

## 🛠 Instalación

Agrega la dependencia en tu archivo `pubspec.yaml`:

```yaml
dependencies:
  downloader_manager:
    git: https://github.com/surco123es/downloader_manager
```

Luego ejecuta:

```bash
dart pub get
```

---

## 💡 Ejemplo de uso completo

```dart
import 'dart:io';
import 'package:downloader_manager/downloader_manager.dart';

void main() async {
  final manDown = DownloaderManager();

  // Inicializa el manager con 3 isolates (hilos de descarga)
  await manDown.init(
      numThread: 3, 
      setting: ManSettings(
        folderOut: 'descargas/',
        folderTemp: 'temporal/',
        conexion: 4,
        limitBand: 8000,
      ),
    );

  // Inicia una descarga
  final response = await manDown.download(
    req: DownRequire(
      url: 'https://tuservidor.com/archivo.zip',
      fileName: 'archivo.exe',
      extension: false,
      tokenDownload: 10001,
    ),
  );

  // Controla la descarga usando el token
  final controller = manDown.controller(response.token);
  if (!controller.exists) return;

  bool pause = false;
  controller.controller!.listen((e) {
    if (e.error) {
      print('❌ Existió un error');
    }
    print('📊 Progreso: ${e.main.porcent}%');
    // Pausa y reanuda automáticamente al 50%
    if (e.main.porcent > 50 && !pause) {
      manDown.pause(response.token);
      print('⏸️ Pausado');
      pause = true;
      sleep(Duration(milliseconds: 3000));
      print('▶️ Continuando');
      manDown.resume(response.token);
    }
    // Cuando termina, libera los isolates
    if (e.main.complete) {
      sleep(Duration(milliseconds: 3000));
      print('🧹 Apagando los isolates');
      manDown.dispose();
    }
  });
}
```

---

## 🧩 API de `DownloaderManager` 

- 🆕 **init({required int numThread, ManSettings? setting})**  
  Inicializa el gestor con el número de isolates deseado.

- 📥 **download({required DownRequire req})**  
  Inicia una nueva descarga.

- ⏸️ **pause(int token)**  
  Pausa la descarga asociada al token.

- ▶️ **resume(int token)**  
  Reanuda la descarga pausada.

- ℹ️ **status(int token)**  
  Obtiene el estado actual de la descarga.

- 📡 **controller(int token)**  
  Obtiene el stream para escuchar el progreso y eventos de la descarga.

- ❌ **cancel({required int token})**  
  Cancela y elimina la tarea de descarga.

- 🧹 **dispose()**  
  Libera todos los recursos y cierra los isolates.

---

## ⚡ Requisitos

- Dart SDK ^3.7.1
- [http](https://pub.dev/packages/http) ^1.1.0

---

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Abre un issue o pull request en [GitHub](https://github.com/surco123es/downloader_manager).

---

## 📄 Licencia

MIT License

---

¡Gestiona tus descargas como un profesional con `downloader_manager`! 🚀🎉