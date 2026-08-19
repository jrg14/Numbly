# Estructura del proyecto

Este documento describe qué debe vivir en cada carpeta del proyecto `Numbly` y por qué existe esa separación.

El objetivo no es solo ordenar archivos:

- evitar dependencias circulares;
- mantener clara la responsabilidad de cada sistema;
- facilitar que el proyecto escale sin volverse caótico;
- hacer más simple encontrar, modificar y testear cada pieza.

## Principios generales

1. Cada carpeta representa una responsabilidad concreta.
1. La lógica de juego va separada de la presentación.
1. Los recursos de datos no deberían contener lógica de escena.
1. Las escenas se usan para composición visual e interacción, no para reglas del juego.
1. Los `autoloads` se reservan para servicios globales o estado compartido.

## Resumen rápido

- `autoload/`: servicios globales.
- `core/`: lógica base del juego.
- `gameplay/`: sistemas que el jugador usa directamente.
- `data/`: contenido editable por niveles, máquinas y progresión.
- `scenes/`: escenas principales de navegación y juego.
- `ui/`: componentes de interfaz.
- `resources/`: clases de recursos reutilizables.
- `assets/`: arte, audio, fuentes y shaders.
- `tests/`: pruebas y escenarios de validación.
- `project.godot`: configuración principal de Godot.

## Documentos relacionados

- [`gdd.md`](gdd.md): visión de diseño del juego.
- [`current-gameplay.md`](current-gameplay.md): comportamiento implementado actualmente.
- [`gameplay-roadmap.md`](gameplay-roadmap.md): objetivos jugables pendientes y prioridades.

---

## `autoload/`

Archivos que se cargan al iniciar el juego y permanecen vivos durante toda la sesión.

### Qué va aquí

- `game_state.gd`
  - Estado global de la partida.
  - Progreso del jugador.
  - Nivel actual, monedas, estrellas, desbloqueos y flags de sesión.
- `save_manager.gd`
  - Guardado y carga de datos.
  - Serialización de progreso.
  - Manejo de slots, versiones de guardado y migraciones simples.
- `scene_router.gd`
  - Cambio centralizado entre escenas.
  - Navegación entre menú, selección de nivel y partida.

### Por qué existe

Los `autoloads` evitan duplicar lógica de acceso global. Son útiles para datos y servicios que deben estar disponibles desde cualquier parte del juego sin depender de una escena concreta.

### Qué no debería ir aquí

- Lógica específica de un nivel.
- Referencias duras a nodos de escenas que pueden descargarse.
- UI concreta.

---

## `core/`

Núcleo de simulación y reglas del juego. Esta carpeta debe contener la lógica más estable y menos dependiente de la interfaz.

### `core/grid/`

Sistema de tablero y posicionamiento.

- `grid_manager.gd`
  - Gestión del tablero.
  - Ocupación de celdas y footprints multi-celda.
  - Consulta de vecinos, límites y validaciones.
- `grid_cell.gd`
  - Representación de una celda del grid.
  - Estado de ocupación, coordenadas y metadatos de la celda.
- `grid_utils.gd`
  - Utilidades matemáticas o de conversión relacionadas con el grid.
  - Funciones puras para no duplicar lógica.

#### Por qué existe

La simulación necesita una base espacial consistente. Separar el grid permite reutilizar el mismo sistema para colocación, visualización y validación sin mezclarlo con la UI.

### `core/simulation/`

Motor lógico de ejecución de números y máquinas.

- `simulation_manager.gd`
  - Orquestación general de la simulación.
  - Reproducción, pausa, avance manual y sincronización de sistemas.
- `simulation_tick.gd`
  - Representación de un paso de simulación.
  - Útil para calcular eventos por frame o por intervalo fijo.
- `number_packet.gd`
  - Unidad que transporta un número o valor.
  - Puede representar payloads que viajan por conveyors u operadores.

#### Por qué existe

La simulación debe ser predecible, testeable y desacoplada de la presentación. Así es más fácil depurar por qué una fábrica produce o no produce un resultado.

### `core/level/`

Reglas, estado y resultados de cada nivel.

- `level_controller.gd`
  - Ciclo de vida de un nivel.
  - Inicio, validación de victoria, derrota y reinicio.
- `level_rules.gd`
  - Restricciones de un nivel.
  - Límites de máquinas, espacio, tiempo, throughput o recursos.
- `level_result.gd`
  - Resultado final del nivel.
  - Medalla, puntuación, métricas y estado de completado.
  - La medalla usa los mismos valores de resultado que la simulación: ticks, tiempo, máquinas y presupuesto.

#### Por qué existe

Los niveles deben definirse como una capa superior a la simulación. Así se pueden crear variantes de objetivos sin reescribir la lógica de máquinas.

---

## `gameplay/`

Sistemas que el jugador usa directamente para construir soluciones.

### `gameplay/buildings/`

Todo lo relativo a máquinas, operadores y edificios colocables.

#### `gameplay/buildings/base/`

Base común para todos los edificios.

- `building.gd`
  - Clase base compartida.
  - API común para entrada, salida, rotación, footprint y comportamiento.
  - Helpers de celdas ocupadas, perímetro y grupos de salida.
- `building.tscn`
  - Escena base visual y de nodos para edificios.

##### Por qué existe

Tener una base común simplifica crear nuevos edificios y garantiza que todos respondan a la misma interfaz.

#### Subcarpetas de edificios

- `source/`
  - Fuentes de números.
  - Generan valores de entrada.
- `conveyor/`
  - Transporte de paquetes entre edificios.
  - No transforman el valor, solo lo mueven.
- `addition/`
  - Máquinas de suma.
  - Transforman o combinan entradas mediante adición.
- `multiplication/`
  - Máquinas de multiplicación.
  - Transforman o combinan entradas mediante multiplicación.
- `output/`
  - Salidas o terminales de objetivo.
  - Registran cuando se entrega el valor correcto.

##### Por qué existe

Separar cada familia de edificios facilita el crecimiento del juego. Más adelante se podrán añadir nuevas categorías sin romper las existentes.

### `gameplay/placement/`

Sistema de colocación en el tablero.

- `placement_controller.gd`
  - Lógica de seleccionar, validar y colocar edificios.
  - Reglas de rotación, coste y colisión.
- `placement_preview.gd`
  - Vista previa del edificio antes de colocarlo.
  - Feedback visual de ubicación válida o inválida.
- `build_command.gd`
  - Objeto de comando para construir, mover, rotar o eliminar.
  - Útil para undo/redo y para registrar acciones.

#### Por qué existe

La colocación es una acción de jugador separada de la simulación. Mantenerla aislada hace más fácil controlar UX, undo y validaciones.

### `gameplay/objectives/`

Definición de objetivos de nivel.

- `objective.gd`
  - Clase base para objetivos.
  - Interfaz común de progreso, validación y completado.
- `target_value_objective.gd`
  - Objetivo de llegar a un valor concreto.
- `throughput_objective.gd`
  - Objetivo de velocidad de producción.
- `machine_limit_objective.gd`
  - Objetivo o restricción relacionada con número de máquinas.

#### Por qué existe

Los objetivos deben ser modulares para combinarse entre sí y crear niveles distintos sin rehacer la estructura del juego.

---

## `data/`

Contenido del juego en formato de datos. Aquí van recursos editables y no lógica de escena.

### `data/levels/`

Definiciones de niveles.

- `level_001.tres`
- `level_002.tres`
- etc.

#### Qué debería contener

- configuración del tablero;
- objetivos;
- recursos iniciales;
- máquinas permitidas;
- límites del nivel;
- condiciones de medalla de bronce, plata y oro;
- parámetros de progresión.

#### Por qué existe

Separar datos de nivel de la lógica permite ajustar balance y contenido sin tocar código.

### `data/buildings/`

Datos de cada tipo de edificio.

- `source_data.tres`
- `adder_data.tres`
- etc.

#### Qué debería contener

- nombre;
- icono;
- coste;
- tiempo o cadencia;
- entradas y salidas;
- descripción;
- restricciones de colocación.

#### Por qué existe

El código define el comportamiento general y los `.tres` concretan valores específicos. Así se puede balancear el juego con rapidez.

### `data/progression/`

Datos de progresión global.

#### Qué va aquí

- desbloqueos por mundo;
- estrellas acumuladas;
- campañas;
- cadenas de progreso;
- tablas de recompensa;
- configuraciones de meta-progresión.

#### Por qué existe

La progresión global conviene mantenerla separada de los niveles individuales para que el guardado y el balance sean más claros.

---

## `scenes/`

Escenas principales del juego. Aquí se organizan pantallas y flujos completos.

### `scenes/boot/`

- `boot.tscn`

#### Qué hace

Escena mínima de arranque.

- carga inicial;
- comprobaciones de entorno;
- redirección a menú o partida;
- precarga de sistemas si hace falta.

#### Por qué existe

Permite centralizar el inicio del juego sin mezclarlo con el menú principal.

### `scenes/main_menu/`

- `main_menu.tscn`

#### Qué hace

Pantalla principal del juego.

- continuar;
- nueva partida;
- ajustes;
- acceso a selección de nivel;
- salida o navegación.

### `scenes/level_select/`

- `level_select.tscn`

#### Qué hace

Pantalla de selección de niveles.

- mundos;
- niveles desbloqueados;
- estado de estrellas;
- progreso general.

### `scenes/game/`

- `game.tscn`

#### Qué hace

Escena de partida.

- tablero;
- HUD;
- colocación;
- simulación;
- pausa;
- feedback de victoria o derrota.

#### Por qué existen estas escenas

Son puntos de entrada visuales y navegables. Mantenerlas separadas reduce acoplamiento y evita que una sola escena crezca demasiado.

---

## `ui/`

Componentes de interfaz reutilizables o paneles específicos.

### `ui/hud/`

- barra superior;
- contador de recursos;
- botones de play/pause;
- estado de objetivo;
- información contextual.

### `ui/building_toolbar/`

- selector de edificios;
- filtros;
- variantes de máquinas;
- coste y disponibilidad.

### `ui/level_complete/`

- panel de victoria;
- estrellas;
- estadísticas finales;
- siguiente nivel.

### `ui/pause/`

- menú de pausa;
- reanudar;
- reiniciar;
- salir;
- opciones rápidas.

### `ui/common/`

- botones reutilizables;
- ventanas modales;
- diálogos;
- widgets compartidos.

#### Por qué existe `ui/`

La UI suele repetirse en varias escenas. Separarla permite reutilizar componentes y mantener consistencia visual.

---

## `resources/`

Clases base de `Resource` usadas por datos y contenido.

- `building_data.gd`
  - Base de datos para edificios.
  - Estructura común para iconos, coste y comportamiento.
- `level_data.gd`
  - Base para datos de nivel.
  - Plantilla de configuración de niveles.
- `objective_data.gd`
  - Base para datos de objetivos.
- `level_medal_data.gd`
  - Define los umbrales de bronce, plata y oro.
  - Cada medalla puede exigir un máximo de ticks y un máximo de máquinas colocadas.

### Por qué existe

Los `Resource` de Godot son ideales para contenido editable en el editor. Permiten que el diseño de niveles y edificios viva en datos, no en lógica hardcodeada.

---

## `assets/`

Archivos estáticos del proyecto.

### `assets/sprites/`

- sprites de edificios;
- iconos;
- elementos de tablero;
- UI rasterizada.

### `assets/fonts/`

- tipografías del juego;
- fuentes para UI y numeración.

### `assets/audio/`

- música;
- efectos de sonido;
- variantes de UI;
- feedback de construcción y simulación.

### `assets/shaders/`

- shaders de materiales;
- efectos visuales;
- resaltado de selección;
- feedback de colocación o error.

#### Por qué existe

Mantener los recursos artísticos agrupados evita mezclar contenido visual con código y facilita exportación, reuso y sustitución.

---

## `tests/`

Casos de prueba y escenas de validación.

### `tests/simulation/`

- pruebas del motor de simulación;
- validación de operadores;
- casos de borde;
- reproducción de ticks.

### `tests/gameplay/`

- pruebas de colocación;
- validación de reglas de nivel;
- pruebas de objetivos;
- escenarios de equilibrio básico.

#### Por qué existe

La simulación y la colocación son los sistemas con más riesgo de regresión. Tener tests aquí ayuda a detectar fallos antes de que lleguen al juego completo.

---

## `project.godot`

Archivo de configuración principal del proyecto.

### Qué suele incluir

- escenas principales;
- autoloads;
- ajustes de render;
- inputs;
- configuración de exportación;
- rutas de recursos.

### Por qué existe

Es el punto central de configuración de Godot. Casi todo el proyecto depende de lo que se declare aquí.

---

## Convenciones recomendadas

### Nombres

- Archivos y carpetas en `snake_case`.
- Clases y scripts con nombres claros y específicos.
- Un archivo, una responsabilidad principal.

### Separación de responsabilidades

- `core/` no debería conocer detalles de UI.
- `ui/` no debería contener reglas de simulación.
- `data/` no debería depender de escenas.
- `autoload/` debería exponer servicios, no lógica de nivel.

### Crecimiento futuro

Si el proyecto crece, la siguiente expansión natural sería:

- `core/pathing/` si aparecen rutas más complejas;
- `gameplay/logic/` si los edificios requieren subcomportamientos;
- `ui/debug/` para herramientas internas;
- `data/worlds/` si la campaña se divide por mundos;
- `tests/regression/` para casos ya corregidos.

---

## Regla práctica para decidir dónde va algo

Si dudas sobre una pieza nueva, usa esta guía:

- ¿Es estado global o servicio compartido? -> `autoload/`
- ¿Es la lógica más baja del juego? -> `core/`
- ¿Es una acción o sistema de jugador? -> `gameplay/`
- ¿Es contenido editable? -> `data/`
- ¿Es una pantalla completa? -> `scenes/`
- ¿Es un componente visual reutilizable? -> `ui/`
- ¿Es una clase de recurso? -> `resources/`
- ¿Es arte, audio o shader? -> `assets/`
- ¿Es validación? -> `tests/`

Si quieres, puedo seguir con el siguiente paso y crear también un documento complementario con:

1. la responsabilidad de cada archivo concreto de la estructura,
2. el orden recomendado de implementación,
3. o una convención de nombres y dependencias para que el proyecto se mantenga limpio.
