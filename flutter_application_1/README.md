# GymTracker - Aplicación de Seguimiento de Entrenamientos

Una aplicación móvil elegante construida con Flutter para registrar y monitorear el progreso de tus entrenamientos. Diseñada para simplificar el registro de pesos levantados, comparar rendimiento con amigos e identificar patrones de mejora a lo largo del tiempo.

## 🎯 Características Principales

- **📅 Planificación Semanal**: Organiza tus entrenamientos por días y secciones musculares
- **💪 Registro Rápido**: Registra peso, repeticiones y notas en segundos
- **📈 Visualización de Progreso**: Gráficos y estadísticas de evolución por ejercicio
- **👥 Comparación con Amigos**: Registra el peso de tus amigos para entrenar juntos
- **📸 Fotos de Transformación**: Almacena fotos de tu progreso corporal
- **💾 Sync Automático**: Todos los datos se guardan localmente
- **🎨 Diseño Moderno**: Interfaz con colores neón optimizada para UX

## 🛠️ Tecnología

- **Framework**: Flutter 3.0+
- **Lenguaje**: Dart
- **Almacenamiento**: SharedPreferences (local)
- **Gráficos**: FL Chart
- **Manejo de Imágenes**: Image Picker

## 📸 Capturas de la App

![Pantalla de inicio](./assets/icons/Screenshot_1773367574.png)
![Detalle del entrenamiento](./assets/icons/Screenshot_1773367584.png)
![Progreso y estadísticas](./assets/icons/Screenshot_1773367588.png)
![Configuración y perfil](./assets/icons/Screenshot_1773367635.png)

## 📁 Estructura del Proyecto

```
lib/
├── main.dart              # Aplicación principal
├── models/
│   ├── ExerciseWeight    # Registro de peso
│   ├── Exercise          # Modelo de ejercicio
│   └── Friend            # Información de amigos
└── pages/
    ├── HomePage          # Vista principal
    ├── DayDetailPage     # Detalles del día
    ├── ProgressPage      # Estadísticas
    └── SettingsPage      # Configuración
```

## 🚀 Cómo Usar

### Iniciar Sesión

1. Abre la aplicación
2. Selecciona un día de la semana
3. Elige un ejercicio
4. Presiona el ícono **editar** (lápiz)
5. Haz clic en **"Reg. Peso Hoy"**
6. Ingresa: peso + reps + notas (opcional)
7. ¡Listo! Auto-guardado ✓

### Funcionalidades

| Función | Descripción |
|---------|------------|
| **Crear Sección** | Agrupa ejercicios por grupos musculares |
| **Nuevo Ejercicio** | Crea un ejercicio con peso y reps iniciales |
| **Registro Rápido** | Registra solo el peso de hoy sin editar plantilla |
| **Agregar Amigos** | Registra amigos para comparar progreso |
| **Ver Gráficos** | Visualiza evolución en la tab "Progresión" |
| **Fotos** | Almacena fotos con peso registrado |

## 📊 Plan de Entrenamientos Predeterminado

```
Lunes    → Pecho + Brazos
Martes   → Espalda
Miércoles → Piernas
Jueves   → Hombro
Viernes  → Pecho + Brazos
Sábado   → Espalda + Piernas
Domingo  → Descanso
```

## 💾 Persistencia de Datos

Todos los datos se guardan **localmente**:

✅ Datos de entrenamientos (ejercicios, pesos, fechas)
✅ Histórico completo de progreso
✅ Fotos de transformación corporal
✅ Información de amigos
✅ Medidas personales (peso, altura)

## 📦 Instalación

### Requisitos

- Flutter 3.0+
- Dart 2.17+
- Android 5.0+ o iOS 11.0+


## 🎨 Personalización

### Cambiar Colores

```dart
const Color _neonCyan = Color(0xFF00F5FF);
const Color _neonPink = Color(0xFFFF2FB1);
const Color _neonPurple = Color(0xFF8D4DFF);
const Color _neonGreen = Color(0xFF5CFF87);
```

### Agregar Ejercicios

Edita `_initializeSampleData()` en `main.dart`:

```dart
'Pecho': {
  'exercises': ['Press de banca', 'Aperturas', 'Fondos'],
  'weights': [80.0, 85.0, 90.0],
},
```

## 🐛 Reporte de Issues

Para reportar bugs o sugerencias, abre un issue en el repositorio.


## 👤 Desarrollador

**Felipe Paimilla**

Ingeniero Civil Informático | Universidad de Playa Ancha

**Experiencia:**
- Automatización de procesos y sistemas
- Desarrollo de aplicaciones con Flutter
- Migración de plataformas CMS
- Soporte técnico y resolución de problemas

**Stack:** Flutter | Dart | Backend | Automatización  
**GitHub:** [github.com/Fpaimilla](https://github.com/Fpaimilla)

---

*Construido con ❤️ en Flutter | Marzo 2026*

