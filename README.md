# 📦✨ downloader_manager

`downloader_manager` es una poderosa librería para Dart que facilita la gestión avanzada de descargas de archivos desde internet. Utiliza rangos de descarga (descarga por partes) y aprovecha isolates para realizar descargas en paralelo sin bloquear la interfaz de usuario ni el hilo principal de tu aplicación. Es ideal para aplicaciones que requieren descargas concurrentes, seguimiento de progreso en tiempo real y control total sobre cada tarea de descarga.

---

## 🚀 Características principales

- 📥 Descarga múltiples archivos simultáneamente sin afectar el rendimiento de tu app.
- ⏸️ Pausa y ▶️ reanuda descargas en cualquier momento.
- 🛑 Detén, cancela y elimina tareas de descarga de forma segura.
- 📊 Monitorea el progreso y estado de cada descarga con streams reactivos.
- 🏷️ Identifica y controla descargas mediante tokens únicos.
- ⚡ Descarga archivos por rangos (descarga por partes) para mayor eficiencia.
- 🧩 Gestiona errores y eventos en tiempo real para una experiencia robusta.
- 🧵 Aprovecha isolates para descargas en paralelo y mayor rendimiento.
- 🧹 Libera recursos y cierra todos los isolates fácilmente.
- 🗂️ Personaliza carpetas de salida y temporales.
- 🚦 Limita el ancho de banda y el número de conexiones por descarga.

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

  // Ejemplo: Pausar y reanudar la descarga automáticamente al 50%
  bool pause = false;
  controller.controller!.listen((e) {
    if (e.error) {
      print('❌ Existió un error');
    }
    print('📊 Progreso: ${e.main.porcent}%');
    if (e.main.porcent > 50 && !pause) {
      manDown.pause(response.token);
      print('⏸️ Descarga pausada');
      pause = true;
      Future.delayed(Duration(seconds: 3), () {
        print('▶️ Reanudando descarga');
        manDown.resume(response.token);
      });
    }
    if (e.main.complete) {
      Future.delayed(Duration(seconds: 3), () {
        print('🧹 Apagando los isolates');
        manDown.dispose();
      });
    }
  });

  // Ejemplo: Consultar el estado actual de la descarga
  final status = manDown.status(response.token);
  print('ℹ️ Estado actual: ${status.status}');

  // Ejemplo: Cancelar la descarga en cualquier momento
  // manDown.cancel(token: response.token);

  // Ejemplo: Forzar la descarga si el archivo ya existe (renombrando)
  // manDown.forzeDownload(token: response.token, rename: 'nuevo_nombre.exe');

  // Ejemplo: Verificar si existe una descarga activa para un token
  // final exists = manDown.checkDownload(response.token);
  // print('¿Existe la descarga?: ${exists.exists}');
}
```

---

## 🧩 API de `DownloaderManager` con ejemplos

- 🆕 **init({required int numThread, ManSettings? setting})**  
  Inicializa el gestor con el número de isolates deseado.
  ```dart
  await manDown.init(numThread: 3, setting: ManSettings());
  ```

- 📥 **download({required DownRequire req})**  
  Inicia una nueva descarga.
  ```dart
  final response = await manDown.download(
    req: DownRequire(
      url: 'https://tuservidor.com/archivo.zip',
      fileName: 'archivo.exe',
      tokenDownload: 10001,
    ),
  );
  ```

- ⏸️ **pause(int token)**  
  Pausa la descarga asociada al token.
  ```dart
  manDown.pause(response.token);
  ```

- ▶️ **resume(int token)**  
  Reanuda la descarga pausada.
  ```dart
  manDown.resume(response.token);
  ```

- ℹ️ **status(int token)**  
  Obtiene el estado actual de la descarga.
  ```dart
  final status = manDown.status(response.token);
  print('Estado: ${status.status}');
  ```

- 📡 **controller(int token)**  
  Obtiene el stream para escuchar el progreso y eventos de la descarga.
  ```dart
  final controller = manDown.controller(response.token);
  controller.controller!.listen((e) {
    print('Progreso: ${e.main.porcent}%');
  });
  ```

- ❌ **cancel({required int token})**  
  Cancela y elimina la tarea de descarga.
  ```dart
  manDown.cancel(token: response.token);
  ```

- 🧹 **dispose()**  
  Libera todos los recursos y cierra los isolates.
  ```dart
  manDown.dispose();
  ```

- 🛠️ **forzeDownload({required int token, String? rename})**  
  Fuerza la descarga de un archivo existente, permitiendo renombrar el archivo destino.
  ```dart
  manDown.forzeDownload(token: response.token, rename: 'nuevo_nombre.exe');
  ```

- 🔍 **checkDownload(int tokenDownload)**  
  Verifica si existe una descarga activa para el token dado.
  ```dart
  final exists = manDown.checkDownload(response.token);
  print('¿Existe la descarga?: ${exists.exists}');
  ```
- ⚡ **fastDownload(int tokenDownload)**  
  Pausa todas las descargas activas y da prioridad máxima a la descarga asociada al token indicado, reanudándola si estaba pausada.
  ```dart
  manDown.fastDownload(response.token);
  ```
---

## ⚙️ Configuración avanzada

Puedes personalizar el comportamiento de las descargas usando la clase `ManSettings`:

```dart
ManSettings(
  conexion: 4, // Número de conexiones por archivo
  folderTemp: 'temporal/', // Carpeta temporal
  folderOut: 'descargas/', // Carpeta de salida
  limitBand: 8000, // Límite de ancho de banda (KB/s)
)
```

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