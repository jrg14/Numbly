# Funcionamiento actual del juego

Este documento describe cómo funciona `Numbly` en el estado actual del código.

La intención de diseño general vive en [`docs/gdd.md`](gdd.md). Este archivo, en cambio, documenta el comportamiento implementado: flujo de nivel, construcción, simulación, edificios, objetivos, medallas y progreso.

Los objetivos jugables pendientes están recogidos en [`gameplay-roadmap.md`](gameplay-roadmap.md).

## Resumen

`Numbly` es actualmente un puzzle de automatización numérica por niveles.

En cada nivel hay:

- un tablero en forma de grid;
- edificios iniciales bloqueados, normalmente fuentes numéricas y outputs;
- una lista limitada de edificios colocables por el jugador;
- objetivos principales y restricciones;
- condiciones de medalla.

El jugador construye una pequeña red para mover paquetes numéricos desde las fuentes, transformarlos con operadores y entregarlos en un output con el valor solicitado.

En el contenido actual, los edificios colocables disponibles por datos son:

- `Conveyor`;
- `Addition`;
- `Multiplication`;
- `Subtraction`;
- `Division`;
- `Modulo`;
- `Splitter`;
- `Buffer`;
- `Merger`;
- `Filter`;
- `Gate`.

El contenido actual está organizado en bloques de 5 niveles: suma, multiplicación, resta, división y módulo. Las piezas logísticas y de control ya existen en datos, pero todavía no tienen bloques de niveles dedicados.

## Flujo de una partida

La escena principal de partida es `scenes/game/game.gd`.

Al entrar al nivel:

1. `GameState` devuelve el nivel seleccionado.
1. `Game` conecta botones, UI, controlador de nivel, controlador de colocación y simulación.
1. Se llama a `reset_level()`.
1. La simulación se detiene y vuelve a tick `0`.
1. El historial de undo/redo se limpia.
1. `LevelController` carga el `LevelData`.
1. El grid se ajusta al tamaño del nivel.
1. Se colocan los edificios iniciales definidos por el nivel.
1. Se configuran los edificios disponibles para el jugador.
1. Se refrescan rutas de conveyors, objetivos y progreso de medalla.

Durante el nivel, el jugador puede alternar entre construir y simular. Si cambia el layout, la simulación se reinicia.

## Datos de nivel

Los niveles están definidos como recursos `.tres` en `data/levels/`.

Cada `LevelData` puede definir:

- `id`;
- `display_name`;
- `objective_text`;
- `grid_size`;
- `initial_buildings`;
- `allowed_buildings`;
- `objectives`;
- `max_buildings`;
- `max_ticks`;
- `medal_conditions`;
- `star_conditions`.

Los edificios iniciales usan `LevelBuildingData`. Esto permite configurar por nivel:

- celda;
- rotación;
- si el edificio está bloqueado;
- valor generado por una fuente;
- valor objetivo de un output;
- cantidad requerida;
- tamaño de buffer;
- intervalo de operación.

Los niveles actuales van de `level_001.tres` a `level_025.tres`.

## Construcción

La construcción está controlada por `gameplay/placement/placement_controller.gd`.

El jugador puede:

- seleccionar edificios con los botones de UI;
- seleccionar edificios desde una paleta inferior adaptada a pantallas táctiles;
- usar teclas `1` a `9` y `0` para seleccionar edificios;
- pulsar `R` para rotar;
- colocar con click izquierdo o touch;
- arrastrar para colocar conveyors en cadena;
- activar `Borrar` y tocar/arrastrar sobre piezas colocadas para eliminarlas en pantallas táctiles;
- borrar con click derecho si está habilitado;
- borrar con `Delete` o `Backspace`;
- deshacer con `Ctrl+Z`;
- rehacer con `Ctrl+Y`.

Reglas de colocación:

- solo se puede colocar dentro del grid;
- solo se puede colocar en celdas libres;
- el nivel puede limitar el número máximo de edificios colocados;
- los edificios bloqueados no se pueden eliminar;
- cada acción de colocar o eliminar se guarda como `BuildCommand`;
- undo/redo reejecuta o revierte esos comandos;
- tras cada cambio, se recalculan rutas de conveyors y se emite `layout_changed`.

La vista previa de colocación instancia la escena real del edificio seleccionado. Si el jugador rota antes de colocar, la preview rota igual que la pieza final; ya no se dibuja un rectángulo/flecha auxiliar encima del grid.

Cuando `Game` recibe `layout_changed`:

1. marca el nivel como no completado;
1. resetea la simulación;
1. recalcula métricas de layout;
1. refresca el progreso de medallas;
1. muestra un mensaje de estado.

## Android y pantallas táctiles

El proyecto está configurado para una experiencia landscape en Android:

- viewport base `1280x720`;
- orientación `SCREEN_SENSOR_LANDSCAPE`;
- entrada táctil directa para colocar, arrastrar y borrar;
- tablero centrado y escalado según el tamaño del nivel y del viewport;
- controles principales en la parte superior;
- paleta de construcción inferior con botones grandes;
- botón táctil `Borrar` para eliminar piezas sin depender de clic derecho o teclado.

## Grid

El tablero está gestionado por `core/grid/grid_manager.gd`.

El grid:

- guarda el tamaño en celdas;
- convierte posiciones entre mundo y celda;
- comprueba si una celda está dentro de límites;
- comprueba si una celda está ocupada;
- coloca piezas centradas en el footprint que ocupan;
- registra el mismo ocupante en cada celda cubierta por su footprint;
- elimina piezas;
- dibuja líneas de grid y celdas ocupadas.

Cada edificio colocado en el grid guarda su `grid_position`, que representa la esquina superior izquierda de su footprint.

El tamaño de footprint vive en `BuildingData.footprint_size` y se copia al edificio instanciado. En los datos actuales:

- fuentes y operadores aritméticos usan `2x2`;
- conveyors y outputs se mantienen en `1x1`;
- el grid de los niveles se ha duplicado para conservar espacio jugable alrededor de los footprints nuevos.

## Simulación

La simulación está gestionada por `core/simulation/simulation_manager.gd`.

Por defecto corre a `10` ticks por segundo. Internamente acumula `delta` de `_process()` y ejecuta ticks fijos cuando el acumulador supera el intervalo calculado.

En cada tick:

1. aumenta `tick_index`;
1. sincroniza conexiones a señales de edificios;
1. busca nodos simulables;
1. llama a `simulation_tick(delta)` en cada nodo que tenga ese método;
1. emite `simulation_tick_completed`.

Un nodo participa en la simulación si implementa `simulation_tick()`.

## Paquetes numéricos

Los números viajan como `NumberPacket`, definido en `core/simulation/number_packet.gd`.

Un paquete contiene:

- `value`;
- `source_id`.

Cuando una fuente emite hacia varias direcciones, se duplican paquetes para que cada dirección reciba su propia instancia.

## Enrutamiento de paquetes

Cuando un edificio emite un paquete, `SimulationManager` decide a donde va.

Comportamiento actual:

- si el edificio emisor es `SourceBuilding`, intenta enviar una copia del paquete por cada celda de perímetro de su footprint;
- una fuente `2x2` tiene 8 celdas de salida potenciales: 2 arriba, 2 a la derecha, 2 abajo y 2 a la izquierda;
- si una celda de salida de fuente no tiene receptor, la fuente simplemente la ignora;
- si el emisor no es una fuente, envía el paquete a sus grupos de salida;
- una salida combinada puede probar varias celdas destino, pero consume un único paquete lógico;
- si no hay receptor en ninguna celda destino del grupo, se emite `connection_error` y `packet_blocked`;
- si hay receptor pero rechaza el paquete, también se emite error y bloqueo;
- si el receptor acepta, se emite `packet_transferred`.

Esto significa que las fuentes funcionan como emisores omnidireccionales por celda de borde, mientras que conveyors y operadores tienen salidas direccionales o grupos de salida definidos por su footprint.

## Edificios

Todos los edificios heredan de `gameplay/buildings/base/building.gd`.

La clase base define:

- `building_data`;
- `grid_position`;
- `footprint_size`;
- `facing`;
- `locked`;
- señales de salida, aceptación y rechazo de paquetes;
- API común para aceptar paquetes por edificio o por celda concreta;
- helpers para celdas ocupadas, perímetro y grupos de salida;
- rotación en pasos de 90 grados;
- emisión de paquetes.

Por defecto, un edificio no acepta paquetes. Cada tipo concreto redefine esa lógica.

### Source

Script: `gameplay/buildings/source/source_building.gd`

La fuente:

- tiene un `generated_value`;
- genera un paquete cada `generation_interval_ticks`;
- ocupa `2x2` en los datos actuales;
- emite una copia independiente hacia cada una de las 8 celdas adyacentes a sus lados;
- no acepta paquetes entrantes;
- configura su valor desde `LevelBuildingData`;
- muestra el valor en `ValueLabel`.

Nota actual: existe `packets_per_second`, pero la generación real usa `generation_interval_ticks`. Si ambos valores no coinciden, manda `generation_interval_ticks`.

### Conveyor

Script: `gameplay/buildings/conveyor/conveyor_building.gd`

El conveyor:

- acepta paquetes mientras no supere `max_packet_capacity`;
- rechaza paquetes que llegan desde su propia dirección de salida;
- guarda paquetes en una cola interna;
- espera `travel_time`;
- sincroniza `travel_time` con `BuildingData.tick_interval`;
- emite los paquetes listos hacia `facing`;
- puede tener ruta recta o curva según `input_direction` y `facing`;
- muestra marcas de flujo animadas, paquetes en tránsito, capacidad y estado de entrada/salida;
- recalcula su dibujo cuando cambia la ruta o su estado de conexión.

Los conveyors pueden colocarse arrastrando. Durante el arrastre, el controlador pinta una ruta ortogonal celda a celda e intenta ajustar automáticamente entrada y salida para formar una ruta continua.

### Addition

Script: `gameplay/buildings/addition/addition_building.gd`

El sumador:

- ocupa `2x2` en los datos actuales;
- espera `input_count` entradas distintas;
- usa una cola por casilla física de entrada;
- diferencia entrada A y entrada B según la celda por la que entra el paquete;
- acepta paquetes mientras el total en buffers sea menor que `max_buffer_size`;
- cuando tiene al menos un paquete en cada entrada requerida, consume uno de cada buffer;
- suma los valores;
- emite un nuevo `NumberPacket` con el resultado por una salida combinada;
- espera `operation_interval_ticks` antes de poder emitir otra suma.

Por defecto `input_count` es `2`, así que un `Addition` combina dos flujos. Para sumar tres o más fuentes, los niveles actuales encadenan varios `Addition`.

### Operadores aritmeticos

Scripts:

- `gameplay/buildings/multiplication/multiplication_building.gd`;
- `gameplay/buildings/subtraction/subtraction_building.gd`;
- `gameplay/buildings/division/division_building.gd`;
- `gameplay/buildings/modulo/modulo_building.gd`.

Estos operadores comparten la base `ArithmeticOperatorBuilding`.

Comportamiento comun:

- aceptan varias entradas hasta `input_count`;
- guardan paquetes por casilla física de entrada;
- la entrada A siempre se consume antes que B;
- cuando hay un paquete por entrada requerida, consumen uno de cada carril;
- emiten el resultado hacia un grupo de salida combinado en el lado `facing`;
- respetan `max_buffer_size` y `operation_interval_ticks`.

La resta, division y modulo usan el orden A y B como orden de operacion. Así `5 - 3` y `3 - 5` producen resultados distintos de forma estable. `Division` y `Modulo` rechazan divisores `0` en la entrada B.

### Splitter

Script: `gameplay/buildings/splitter/splitter_building.gd`

El splitter acepta paquetes y los reparte entre dos salidas: `facing` y la direccion perpendicular horaria. Por defecto alterna entre ambas. Tambien soporta modos exportados de duplicacion y prioridad.

### Buffer y Merger

Scripts:

- `gameplay/buildings/buffer/buffer_building.gd`;
- `gameplay/buildings/merger/merger_building.gd`.

`Buffer` almacena paquetes hasta `max_buffer_size` y libera uno cada `release_interval_ticks`. `Merger` reutiliza esa logica para combinar varias lineas en una salida comun.

### Filter

Script: `gameplay/buildings/filter/filter_building.gd`

El filtro acepta paquetes y decide su salida segun `filter_mode` y `compare_value`. Los paquetes que cumplen salen hacia `facing`; los que no cumplen salen por la direccion perpendicular horaria si `route_failed_packets` esta activo.

### Gate

Script: `gameplay/buildings/gate/gate_building.gd`

La puerta controla el flujo. Puede dejar pasar cada N paquetes, dejar pasar solo un valor concreto, o bloquear un valor concreto. Los paquetes que no pasan se consumen sin emitir salida.

### Output

Script: `gameplay/buildings/output/output_building.gd`

El output:

- acepta cualquier paquete;
- compara `packet.value` contra `target_value`;
- si coincide, aumenta `accepted_count`;
- si no coincide, aumenta `rejected_count`;
- emite `packet_consumed` tanto para aciertos como para errores;
- al alcanzar `required_count`, marca `is_complete` y emite `target_reached`.

El output consume el paquete incluso si el valor es incorrecto.

## Visualización de paquetes

`Game` escucha eventos de simulación y los pasa a `PacketVisualizer`.

Actualmente se visualiza:

- transferencia entre edificios;
- paquete bloqueado;
- paquete recibido por output;
- resultado de una suma.

También se actualiza `status_label` con mensajes como transferencia, bloqueo, error o completado.

## Lectura de puertos

La ayuda direccional por hover está activa en la escena de juego mediante `RouteOverlay`. Al pasar sobre una pieza o una previsualización, el overlay muestra entradas, salidas, conexiones posibles y bloqueos.

La lectura principal vive en el sprite del edificio:

- los conveyors muestran flujo animado, puertos abiertos/conectados y saturación;
- los operadores aritméticos son amarillos;
- en orientación base, `B` está en la celda superior izquierda;
- `A` está en la celda superior derecha;
- la mitad inferior no tiene divisor vertical y funciona como salida combinada;
- la fórmula inferior (`A+B`, `A-B`, `AxB`, `A/B`, `A%B`) marca esa salida combinada;
- al rotar un edificio, las posiciones de `A`, `B` y la fórmula giran junto con los puertos lógicos;
- las etiquetas compensan su rotación para mantenerse legibles para el jugador;
- el overlay complementa el sprite cuando hace falta leer una conexión antes de colocar.

Esto mantiene visible el orden de operaciones no conmutativas y reduce la colocación por ensayo y error.

## Objetivos

Los objetivos están definidos en `resources/objective_data.gd` y se instancian desde `gameplay/objectives/objective.gd`.

Tipos actuales:

- `TARGET_VALUE`;
- `THROUGHPUT`;
- `MACHINE_LIMIT`;
- `TIME_LIMIT`;
- `BUDGET_LIMIT`.

Cada objetivo puede ser principal o restricción mediante `is_constraint`.

### Target value

Se completa cuando las métricas registran suficientes paquetes correctos del valor objetivo.

Ejemplo:

```text
Numero 5 conseguido: 1/1
```

### Throughput

Se completa cuando, en una ventana reciente de tiempo, se han producido suficientes paquetes correctos.

Puede usar:

- `required_count`;
- o `throughput_per_second * duration_seconds`.

### Machine limit

Falla si el número de máquinas colocadas por el jugador supera `max_buildings`.

Los edificios bloqueados del nivel no cuentan. Los `Conveyor` tampoco cuentan como máquinas para este objetivo ni para las medallas por número de edificios.

### Time limit

Falla si se supera `max_ticks` o `duration_seconds`.

### Budget limit

Falla si el presupuesto gastado supera `max_budget`.

El coste viene de `BuildingData.cost`.

Costes actuales principales:

- `Conveyor`: `1`;
- `Addition`: `3`;
- `Source`: `0`;
- `Output`: `0`.

## Métricas

Las métricas viven en `core/level/level_metrics.gd`.

Se registran:

- tick actual;
- segundos transcurridos;
- máquinas colocadas por el jugador, excluyendo `Conveyor`;
- presupuesto gastado;
- paquetes consumidos por valor;
- paquetes correctos por valor;
- eventos recientes de output.

Las métricas se actualizan:

- en cada tick;
- cuando un output consume un paquete;
- cuando cambia el layout.

## Completar o fallar un nivel

La decisión vive en `core/level/level_controller.gd`.

Después de actualizar objetivos:

1. Si alguna restricción falla, el nivel falla.
1. Si todos los objetivos principales están completos, se calcula medalla.
1. Si hay condiciones de medalla y no se alcanza al menos bronce, el nivel falla.
1. Si se alcanza bronce o mejor, se crea un `LevelResult`.
1. `Game` guarda el resultado, pausa la simulación y muestra el overlay de completado.

El overlay permite:

- reintentar;
- ir al siguiente nivel si existe;
- volver al menú principal.

## Medallas y estrellas

Las medallas están definidas con `LevelMedalData`.

Una medalla se gana si las métricas cumplen:

- `max_ticks`;
- `max_buildings`.

El nivel calcula la mejor medalla disponible entre:

- bronce;
- plata;
- oro.

En la práctica actual, `stars` se iguala al valor de medalla en `LevelResult`.

También existe `StarConditionData`, pero cuando hay `medal_conditions`, el flujo principal usa medallas para el resultado visible y guardado.

## Guardado y selección de niveles

`GameState` guarda la ruta del nivel seleccionado y permite avanzar al siguiente nivel usando una lista explícita de rutas de nivel. Esta lista evita depender de listar directorios `res://` en Android.

`SaveManager` guarda progreso en:

```text
user://progress.cfg
```

Solo guarda resultados completados con medalla mayor que `NONE`.

Para cada nivel guarda:

- completado;
- mejor medalla;
- mejores ticks;
- mejores segundos;
- menor número de edificios si empata en ticks;
- presupuesto;
- fecha de actualización.

Si se repite un nivel, el guardado solo mejora si:

1. la nueva medalla es mayor;
1. o la medalla empata y los ticks son menores;
1. o también empatan los ticks y se usan menos edificios.

## Estado actual del contenido

Hay 25 niveles definidos en `data/levels/`.

El contenido actual se organiza así:

- `level_001` a `level_005`: suma;
- `level_006` a `level_010`: multiplicación;
- `level_011` a `level_015`: resta;
- `level_016` a `level_020`: división;
- `level_021` a `level_025`: módulo.

Cada bloque de operación introduce:

- dos fuentes bloqueadas;
- un output bloqueado;
- `Conveyor`;
- el edificio de operación correspondiente;
- objetivos de valor;
- límites de máquinas, tiempo y presupuesto;
- medallas con umbrales de ticks y máquinas.

Valores objetivo actuales incluyen, entre otros:

- `5`;
- `8`;
- `9`;
- `16`;
- `20`;
- `36`;
- `42`;
- `12`;
- `24`;
- restos como `1`, `4` y `5`.

## Diferencias con la visión del GDD

El GDD plantea una visión más amplia que el estado actual del código.

Implementado actualmente:

- grid;
- fuentes;
- conveyors;
- sumadores;
- outputs;
- objetivos;
- restricciones;
- medallas;
- guardado de progreso;
- selección de niveles;
- visualización básica de paquetes.

Planteado o preparado, pero no presente como gameplay completo actual:

- multiplicadores jugables;
- splitters;
- operaciones más allá de suma;
- reglas avanzadas de distribución;
- sistemas incrementales;
- monetización/anuncios;
- progresión compleja de desbloqueos;
- mobile UX final.

Este documento debe actualizarse cuando cambie el comportamiento implementado, especialmente al añadir nuevos edificios u objetivos.
