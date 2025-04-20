# 📦✨ downloader_manager

`downloader_manager` es una poderosa librería para Dart que facilita la gestión avanzada de descargas de archivos desde internet. Permite crear, monitorear, pausar, reanudar y detener descargas de manera eficiente y controlada, utilizando aislamiento de procesos (`Isolate`) para no bloquear la interfaz de usuario ni el hilo principal de tu aplicación. Es ideal para aplicaciones que requieren descargas concurrentes, seguimiento de progreso en tiempo real y control total sobre cada tarea de descarga.

Con `downloader_manager` puedes:

- 📥 Descargar múltiples archivos simultáneamente sin afectar el rendimiento de tu app.
- ⏸️ Pausar y ▶️ reanudar descargas en cualquier momento.
- 🛑 Detener y eliminar tareas de descarga de forma segura.
- 📊 Monitorear el progreso y estado de cada descarga con streams reactivos.
- 🏷️ Identificar y controlar descargas mediante tokens únicos.
- ⚠️ Gestionar errores y eventos en tiempo real para una experiencia robusta.

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
import 'package:downloader_manager/downloader_manager.dart';

void main() async {
  final manager = ManagerDownload();

  // 1️⃣ Crear una descarga
  final response = await manager.create(
    req: DownRequire(
      url: 'https://www.ejemplo.com/archivo.zip',
      fileName: 'archivo.zip',
      token: 12345,
    ),
  );

  final token = response.token;

  // 2️⃣ Escuchar el progreso de la descarga
  final controller = manager.controller(token);
  if (controller.exists) {
    controller.controller!.listen((status) {
      print('📊 Progreso: ${status.main.porcent}%');
      if (status.error) {
        print('❌ Error en la descarga');
      }
    });
  }

  // 3️⃣ Pausar la descarga
  bool paused = manager.pause(token);
  print(paused ? '⏸️ Descarga pausada' : '⚠️ No se pudo pausar');

  // 4️⃣ Reanudar la descarga
  bool resumed = manager.resume(token);
  print(resumed ? '▶️ Descarga reanudada' : '⚠️ No se pudo reanudar');

  // 5️⃣ Consultar el estado de la descarga
  final status = manager.status(token);
  print('ℹ️ Estado actual: ${status.pause ? "⏸️ Pausada" : "✅ Activa"}');

  // 6️⃣ Detener y eliminar la descarga
  bool stopped = await manager.stop(token: token);
  print(stopped ? '🛑 Descarga detenida y eliminada' : '⚠️ No se pudo detener');
}
```

---

## 🧩 API de `ManagerDownload` 

- 🆕 **create({required DownRequire req, Function? fc})**  
  Crea una nueva tarea de descarga.

- ⏸️ **pause(int token)**  
  Pausa la descarga asociada al token.

- ▶️ **resume(int token)**  
  Reanuda la descarga pausada.

- ℹ️ **status(int token)**  
  Obtiene el estado actual de la descarga.

- 📡 **controller(int token)**  
  Obtiene el stream para escuchar el progreso y eventos de la descarga.

- 🛑 **stop({required int token})**  
  Detiene y elimina la tarea de descarga.

---

## ⚡ Requisitos

- Dart SDK ^3.7.1
- [http](https://pub.dev/packages/http) ^1.1.0

---



## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Abre un issue o pull request en [GitHub](https://github.com/surco123es/downloader_manager).

---


¡Gestiona tus descargas como un profesional con `downloader_manager`! 🚀🎉