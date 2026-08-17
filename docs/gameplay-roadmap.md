# Objetivos jugables por hacer

Este documento recoge mejoras jugables pendientes para `Numbly`.

No describe comportamiento implementado. Para el estado actual del juego, ver [`current-gameplay.md`](current-gameplay.md). Para la visión general de diseño, ver [`gdd.md`](gdd.md).

Nota de estado: las piezas base `Multiplication`, `Subtraction`, `Division`, `Modulo`, `Splitter`, `Buffer`, `Merger`, `Filter` y `Gate` ya tienen una primera implementación jugable y recursos de datos. Lo pendiente alrededor de ellas es sobre todo balance, UI de configuración, tutorialización, niveles dedicados y pulido visual.

## Criterio de priorización

Las mejoras se ordenan pensando en:

- aumentar claridad para el jugador;
- mejorar la capacidad de depurar fábricas;
- añadir profundidad sin romper el loop actual;
- aprovechar los sistemas existentes de grid, edificios, paquetes, objetivos y medallas;
- crear piezas que permitan muchos niveles nuevos con poco código adicional.

## Prioridad recomendada

Yo empezaría por este orden:

1. **Velocidad de simulación y paso a paso**
1. **Feedback visual de rutas y bloqueos**
1. **Splitter**
1. **Buffer**
1. **Objetivos múltiples y throughput más visible**

Motivo: antes de añadir demasiada complejidad matemática, conviene que el jugador entienda mejor qué está pasando. Si una fábrica falla, el jugador debe poder verlo, pausarlo, avanzar tick a tick y localizar el problema. Después de eso, piezas como `Splitter` y `Buffer` multiplican la profundidad del juego sin cambiar su identidad.

## Mejoras de core gameplay

### Más operaciones

Añadir nuevos edificios de transformación numérica.

Opciones:

- multiplicador;
- restador;
- divisor entero;
- duplicador;
- inversor;
- módulo;
- potencia simple.

Valor jugable:

- aumenta la variedad matemática;
- permite niveles con varias soluciones;
- reduce la dependencia de cadenas largas de sumadores;
- acerca el juego a la visión del GDD.

Riesgos:

- demasiadas operaciones pronto pueden hacer que el juego parezca un ejercicio de ecuaciones;
- cada operación necesita niveles de introducción claros;
- algunas operaciones pueden romper el balance si producen atajos demasiado potentes.

### Splitter

Edificio que divide un flujo entrante en varias salidas.

Variantes posibles:

- alternar izquierda/derecha;
- duplicar paquete hacia dos salidas;
- repartir en ronda;
- enviar según prioridad de salida libre.

Valor jugable:

- permite compartir una fuente entre varias rutas;
- crea puzzles de distribución;
- ayuda a objetivos múltiples;
- hace que el diseño de red importe más.

Riesgos:

- si duplica paquetes sin coste puede romper throughput y balance;
- si alterna sin feedback visual puede ser difícil de entender;
- necesita buena visualización de salida activa.

### Merger

Edificio que combina varias rutas en una salida común sin transformar el valor.

Valor jugable:

- permite reorganizar flujos;
- reduce cruces y rutas largas;
- ayuda a construir fábricas más compactas.

Riesgos:

- puede crear bloqueos si no hay reglas claras de prioridad;
- necesita comportamiento definido cuando llegan paquetes simultáneos.

### Buffer

Edificio que almacena paquetes y los libera con una regla concreta.

Variantes posibles:

- liberar uno cada cierto número de ticks;
- liberar cuando se llena;
- liberar bajo demanda;
- mantener un máximo de paquetes.

Valor jugable:

- introduce sincronización;
- ayuda a estabilizar throughput;
- permite resolver diferencias de ritmo entre fuentes y operadores;
- crea puzzles de temporización sin añadir operaciones matemáticas.

Riesgos:

- si no se visualiza el contenido del buffer, puede parecer opaco;
- puede ralentizar demasiado el ritmo si se usa en niveles tempranos.

### Filtros por valor

Edificio que solo deja pasar paquetes que cumplen una condición.

Opciones:

- igual a un valor;
- distinto de un valor;
- mayor que;
- menor que;
- par/impar;
- múltiplo de N.

Valor jugable:

- permite separar resultados;
- hace viables redes con errores controlados;
- abre niveles con múltiples outputs;
- permite soluciones más expresivas.

Riesgos:

- requiere UI clara para configurar la condición;
- puede solaparse con futuros objetivos de pureza o error.

### Puertas lógicas simples

Edificios que alteran el flujo sin cambiar necesariamente el valor.

Opciones:

- dejar pasar cada N paquetes;
- alternar salida;
- activar salida solo si llega cierto valor;
- bloquear hasta recibir una señal;
- contar paquetes y emitir al llegar a un umbral.

Valor jugable:

- acerca el juego a automatización real;
- crea puzzles de control;
- permite soluciones más elegantes que solo alargar conveyors.

Riesgos:

- puede subir mucho la complejidad cognitiva;
- debería llegar después de que transporte, suma, split y buffer estén consolidados.

## Mejoras de objetivos

### Objetivos múltiples

Permitir que un nivel exija varios resultados.

Ejemplos:

- producir `8` y `13`;
- producir `5` en un output y `9` en otro;
- producir varios valores con una fuente compartida.

Valor jugable:

- obliga a reutilizar infraestructura;
- hace más interesante el uso de splitters;
- genera decisiones de diseño más ricas.

Riesgos:

- sin buena UI de progreso puede ser confuso;
- necesita outputs y objetivos claramente diferenciados.

### Outputs con penalización

Hacer que entregar valores incorrectos tenga consecuencias jugables.

Opciones:

- perder medalla;
- fallar tras X errores;
- reducir puntuación;
- exigir pureza del 100%;
- contar paquetes desperdiciados.

Valor jugable:

- hace que el jugador cuide la precisión;
- da importancia a filtros y rutas limpias;
- permite retos opcionales interesantes.

Riesgos:

- castigar demasiado pronto puede frustrar;
- debe comunicarse antes de pulsar `Play`.

### Throughput más visible

Mejorar cómo se comunica la producción sostenida.

Ideas:

- barra de throughput reciente;
- indicador de paquetes por segundo actual;
- ventana temporal visible;
- aviso de ritmo insuficiente;
- histórico pequeño de producción.

Valor jugable:

- hace legibles los niveles avanzados;
- ayuda a optimizar;
- convierte el throughput en una meta observable, no solo en texto.

Riesgos:

- demasiados números en pantalla pueden saturar;
- debe ser compacto y claro.

### Objetivos de eficiencia variados

Añadir retos más allá de ticks y máquinas.

Opciones:

- presupuesto máximo;
- longitud total de conveyors;
- número máximo de operadores;
- paquetes desperdiciados;
- errores permitidos;
- energía consumida;
- espacio ocupado.

Valor jugable:

- favorece soluciones distintas;
- hace que rejugar por medallas sea más variado;
- permite que un mismo nivel tenga varios estilos de optimización.

Riesgos:

- muchos criterios simultáneos pueden dificultar saber qué optimizar;
- conviene introducirlos como retos opcionales o medallas específicas.

### Contratos opcionales

Separar objetivo principal de retos secundarios.

Ejemplos:

- completar el nivel;
- completar sin errores;
- usar menos de 12 máquinas;
- producir 3 paquetes por segundo;
- gastar menos de 20 de presupuesto.

Valor jugable:

- baja la barrera para avanzar;
- mantiene profundidad para jugadores que quieren optimizar;
- encaja bien con medallas.

Riesgos:

- la UI debe distinguir bien requisito obligatorio y reto opcional.

## Mejoras de sensación jugable

### Modo paso a paso

Permitir avanzar un tick manualmente cuando la simulación está pausada.

Valor jugable:

- ayuda a depurar;
- hace más entendibles los buffers, sumadores y bloqueos;
- mejora la sensación de control.

Riesgos:

- requiere que el estado de simulación sea estable al pausar y avanzar;
- algunos efectos visuales pueden necesitar adaptación.

### Velocidad de simulación

Añadir controles de velocidad.

Opciones:

- `0.5x`;
- `1x`;
- `2x`;
- `4x`;
- avance tick a tick.

Valor jugable:

- reduce esperas;
- permite observar fábricas lentas;
- mejora la experiencia en niveles grandes.

Riesgos:

- velocidades altas pueden hacer ilegibles los paquetes;
- hay que comprobar que la lógica siga siendo determinista.

### Feedback de bloqueo más claro

Mostrar mejor por qué un paquete no avanza.

Motivos a comunicar:

- no hay receptor;
- receptor rechazó el paquete;
- buffer lleno;
- entrada inválida;
- salida mal orientada.

Valor jugable:

- reduce frustración;
- convierte errores en información accionable;
- acelera aprendizaje.

Riesgos:

- puede llenar la pantalla si muchos paquetes fallan a la vez;
- conviene agrupar o limitar mensajes repetidos.

### Vista de rutas

Al seleccionar un edificio, mostrar entradas y salidas relevantes.

Estado actual:

- implementada una primera versión de vista de rutas por hover y preview;
- falta selección persistente de edificios colocados;
- falta integrar motivos detallados de bloqueo en la propia vista;
- falta pulir la presentación visual tras probarla en juego.

Ideas:

- flecha de salida;
- marcas de entradas válidas;
- celdas vecinas conectables;
- ruta actual de conveyor;
- estado de aceptación del receptor vecino.

Valor jugable:

- ayuda a construir sin ensayo y error;
- hace más comprensible la orientación;
- prepara el terreno para edificios más complejos.

Riesgos:

- debe ser visualmente limpio;
- no debería ocultar números ni paquetes.

### Preview de resultado

Mostrar información contextual al colocar o seleccionar operadores.

Ejemplos:

- valores recientes en buffers;
- resultado esperado de un `Addition`;
- entradas detectadas;
- estado de cooldown;
- capacidad restante.

Valor jugable:

- ayuda a entender operadores;
- reduce incertidumbre;
- hace que optimizar sea más agradable.

Riesgos:

- si se muestra demasiada información, puede parecer una herramienta de debug más que juego.

## Mejoras de progresión

### Introducción gradual de piezas

Orden sugerido:

1. fuente, conveyor y output;
1. suma;
1. múltiples paquetes requeridos;
1. throughput;
1. splitter;
1. buffer;
1. objetivos múltiples;
1. filtros;
1. multiplicador;
1. puertas de control.

Valor jugable:

- cada mecánica tiene espacio para aprenderse;
- evita abrumar;
- permite construir una curva de dificultad más clara.

### Mundos por mecánica

Agrupar niveles por tema.

Ejemplos:

- mundo de suma;
- mundo de flujo;
- mundo de sincronización;
- mundo de filtros;
- mundo de multiplicación;
- mundo de optimización.

Valor jugable:

- facilita progresión;
- da identidad a bloques de niveles;
- ayuda a diseñar tutoriales internos.

### Medallas con soluciones distintas

Hacer que las medallas no siempre premien lo mismo.

Ejemplos:

- oro por rapidez;
- oro por pocas máquinas;
- oro por cero errores;
- oro por bajo presupuesto;
- oro por throughput sostenido.

Valor jugable:

- aumenta rejugabilidad;
- evita que optimizar sea siempre acortar conveyors;
- da más personalidad a cada nivel.

### Desbloqueos funcionales

Desbloquear nuevas piezas o tipos de objetivo.

Ejemplos:

- desbloquear `Splitter`;
- desbloquear `Buffer`;
- desbloquear filtros;
- desbloquear objetivos múltiples;
- desbloquear nuevas restricciones.

Valor jugable:

- da sensación de avance;
- ordena el aprendizaje;
- crea expectativa entre mundos.

### Niveles sandbox pequeños

Niveles sin presión fuerte para experimentar.

Valor jugable:

- permite probar piezas nuevas;
- reduce fricción antes de niveles exigentes;
- ayuda a encontrar estrategias emergentes.

Riesgos:

- deben tener algún objetivo mínimo para no sentirse vacíos;
- conviene ubicarlos después de introducir una mecánica nueva.

## Primer bloque de trabajo recomendado

Empezaría por un bloque llamado **Depuración y lectura de fábrica**.

Objetivo:

Hacer que el jugador entienda mejor por qué su máquina funciona o falla antes de añadir nuevas piezas.

Incluye:

1. controles de velocidad `1x`, `2x`, `4x`;
1. botón de avanzar un tick con la simulación pausada;
1. visualización clara de salida de cada edificio;
1. feedback de paquete bloqueado con motivo;
1. panel o texto breve de throughput actual cuando el nivel lo requiere.

Por qué empezaría aquí:

- aprovecha sistemas existentes;
- reduce frustración inmediata;
- mejora todos los niveles actuales sin rehacer contenido;
- prepara el juego para piezas futuras más complejas;
- ayuda a validar si los niveles actuales son divertidos o solo difíciles de leer.

Después de ese bloque, pasaría a **Splitter** como primera pieza nueva.

Motivo:

El `Splitter` añade decisiones de red sin introducir una operación matemática nueva. Es una evolución natural del juego actual: si ya puedes transportar y sumar, el siguiente paso interesante es repartir flujos.

## Segundo bloque recomendado

Después de mejorar lectura y añadir `Splitter`, construiría un bloque de niveles centrado en distribución:

1. nivel tutorial de splitter con una fuente y dos outputs;
1. nivel con una fuente compartida entre dos sumas;
1. nivel con throughput que exige repartir flujo;
1. nivel de medalla por pocas máquinas usando splitter;
1. nivel combinado con `Addition` encadenado.

Este bloque serviría para comprobar si el juego gana profundidad sin volverse confuso.
