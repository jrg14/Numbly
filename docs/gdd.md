# NUMBLY

### Game Design Document — v0.1

**Género:** Puzzle / Automatización / Incremental ligero
**Plataforma inicial:** Android
**Orientación:** Landscape
**Modelo de negocio:** Anuncios
**Público objetivo:** Jugadores de puzzles, automatización, optimización 
**Duración de sesión objetivo:** 3–10 minutos
**Estado:** Concepto / Preproducción

> Nota: este documento describe la visión de diseño. El comportamiento implementado actualmente está documentado en [`current-gameplay.md`](current-gameplay.md).
> Los objetivos jugables pendientes están recogidos en [`gameplay-roadmap.md`](gameplay-roadmap.md).

---

# 1. High Concept

**Numbly** es un juego de puzzles de automatización basado en números.

En cada nivel, el jugador recibe un tablero, unas fuentes numéricas y un conjunto limitado de herramientas. Debe construir una pequeña red de producción capaz de transformar los números disponibles hasta generar el valor solicitado.

El reto no consiste únicamente en descubrir una operación matemática correcta, sino en **diseñar una máquina eficiente capaz de producir el resultado continuamente**.

Ejemplo:

```text
OBJETIVO
Produce 24 a una velocidad de 5/s.

2 ─────┐
       × ── 6 ───┐
3 ─────┘         │
                 × ─── 24 → OUTPUT
2 ─────┐         │
       + ── 4 ───┘
2 ─────┘
```

Los primeros niveles enseñan operaciones sencillas. Gradualmente aparecen restricciones de espacio, velocidad, coste y lógica que transforman el juego en un puzzle de automatización.

La filosofía central es:

> **Entender → Construir → Ejecutar → Observar → Optimizar**

---

# 2. Visión del juego

Numbly debe producir la sensación de haber construido una pequeña máquina inteligente.

El momento satisfactorio no es pulsar un botón para obtener un número.

Es pulsar **PLAY**, observar cómo los números recorren el sistema y ver cómo una construcción diseñada por el jugador empieza a funcionar correctamente.

La experiencia debería evolucionar aproximadamente así:

```text
"Necesito conseguir 8."

        ↓

"4 × 2."

        ↓

"¿Cómo llevo ambos números hasta aquí?"

        ↓

"Funciona."

        ↓

"Pero produce demasiado despacio."

        ↓

"Podría reorganizar esto..."

        ↓

"Ahora produce el doble usando menos espacio."
```

Ese último paso —la optimización voluntaria— debe proporcionar gran parte de la profundidad.

---

# 3. Pilares de diseño

## 3.1 Fácil de entender, difícil de optimizar

Completar un nivel debe ser relativamente accesible.

Optimizarlo debe poder convertirse en un puzzle considerablemente más complejo.

El juego no debe exigir soluciones perfectas para avanzar.

---

## 3.2 La fábrica es la solución

El juego no debe convertirse simplemente en:

> "Encuentra una ecuación que dé 48."

Encontrar la ecuación es solamente una parte.

También importa:

* cómo transportar los números;
* cómo distribuirlos;
* qué máquinas utilizar;
* cuánto espacio ocupar;
* qué throughput alcanzar;
* cómo evitar cuellos de botella.

---

## 3.3 Sistemas antes que contenido

Las mecánicas deben combinarse entre ellas para producir nuevos problemas.

Una nueva máquina debería permitir crear numerosos niveles nuevos sin necesitar sistemas completamente diferentes.

---

## 3.4 Satisfacción visual

La ejecución debe ser agradable de observar.

Los números recorren las líneas, entran en operadores y salen transformados.

Una fábrica bien diseñada debe tener cierto efecto de "salvapantallas":

> **He construido esto y funciona solo.**

---

## 3.5 Mobile first

Numbly no debe sentirse como un juego de PC reducido a una pantalla pequeña.

Interacciones prioritarias:

* tocar;
* arrastrar;
* mantener pulsado;
* pinch-to-zoom si fuera necesario;
* undo inmediato;
* construcción rápida;
* eliminación rápida.

Las sesiones deben poder ser cortas.

---

# 4. Core Gameplay Loop

El loop fundamental de un nivel es:

```text
ENTRAR AL NIVEL

      ↓

ANALIZAR OBJETIVO

      ↓

CONSTRUIR

      ↓

PLAY

      ↓

OBSERVAR

      ↓

¿FUNCIONA?
  ↓        ↓
 NO        SÍ
 ↓          ↓
EDITAR    COMPLETAR
            ↓
         OPTIMIZAR
            ↓
         ESTRELLAS
            ↓
      SIGUIENTE NIVEL
```

El jugador puede alternar libremente entre construcción y simulación.

---

# 5. Estructura de un nivel

Cada nivel contiene:

### Objetivo principal

Ejemplo:

**Produce 24**

Puede requerirse también mantener determinado throughput:

**Produce ≥ 5 unidades/s durante 10 segundos.**

---

### Recursos iniciales

Ejemplo:

```text
Fuente: 2
Fuente: 3
Fuente: 5
```

---

### Herramientas disponibles

Ejemplo:

```text
Transportador
Sumador
Multiplicador
Splitter
```

---

### Tablero

Cada nivel tiene dimensiones específicas.

Ejemplo:

```text
10 × 10
```

El tamaño del tablero puede convertirse posteriormente en parte del puzzle.

---

# 6. Sistema de estrellas

Cada nivel ofrece hasta tres estrellas.

Ejemplo:

### Nivel 17 — Target: 48

⭐ Produce 48.

⭐⭐ Produce ≥ 8/s.

⭐⭐⭐ Utiliza ≤ 5 operadores.

La primera estrella representa completar el nivel.

Las estrellas adicionales representan optimización.

Nunca debería ser necesario obtener tres estrellas en todos los niveles para continuar la campaña principal.

---

# 7. Sistema de construcción

El mundo utiliza una cuadrícula.

Cada celda puede contener una pieza.

Tipos iniciales:

### Source

Genera continuamente un número.

```text
[3] → 3 → 3 → 3 → 3
```

Propiedades:

```text
Value
ProductionRate
Direction
```

---

### Conveyor

Transporta números.

```text
3 → 3 → 3 → 3 →
```

Puede colocarse mediante drag para dibujar varios segmentos rápidamente.

---

### Output

Representa el objetivo.

```text
→ [24]
```

Solamente acepta el valor solicitado.

Cuando recibe suficiente producción durante el tiempo requerido, el nivel se completa.

---

# 8. Operadores

## Addition

Recibe dos números:

```text
A + B
```

Ejemplo:

```text
3 + 5 → 8
```

---

## Multiplication

```text
A × B
```

Ejemplo:

```text
3 × 5 → 15
```

---

## Subtraction

```text
A - B
```

El orden de las entradas importa.

---

## Division

```text
A ÷ B
```

Inicialmente podría limitarse a resultados enteros.

La división por cero nunca está permitida.

---

# 9. Logística

Las operaciones matemáticas por sí solas no deben resolver todo el juego.

La logística proporciona la segunda dimensión.

## Splitter

```text
        → A
INPUT →
        → B
```

Distribuye alternativamente los elementos entre dos salidas.

---

## Merger

```text
A ─┐
   ├→ OUTPUT
B ─┘
```

Combina dos líneas.

---

## Filter

Mecánica avanzada.

Ejemplo:

```text
          → valores = 8
INPUT → [FILTER]
          → resto
```

---

# 10. Simulación

La simulación funciona mediante ticks.

Ejemplo conceptual:

```text
SimulationRate = 10 ticks/s
```

Cada máquina procesa elementos según:

```text
InputBuffer
ProcessingTime
OutputBuffer
```

No es necesario utilizar físicas.

Los números visuales son una representación de datos internos.

Esto permite mantener un comportamiento determinista y mejorar el rendimiento en dispositivos móviles.

---

# 11. Throughput

Una parte fundamental de Numbly será el **flujo de producción**.

No basta con producir una vez:

```text
24
```

Los niveles avanzados pueden exigir:

```text
24 × 10/s
```

Esto introduce problemas de:

* capacidad;
* paralelización;
* distribución;
* cuellos de botella;
* espacio.

El jugador pasa de resolver matemáticas a resolver ingeniería.

---

# 12. Progresión

La campaña está dividida en mundos.

## Mundo 1 — Foundations

Conceptos:

```text
Sources
Conveyors
Addition
```

Objetivo:

Enseñar construcción y flujo.

---

## Mundo 2 — Multiplication

Introduce:

```text
Multiplication
Splitter
```

Empiezan los problemas de throughput.

---

## Mundo 3 — Routing

Introduce:

```text
Merger
Bridges/Crossings
```

Los niveles empiezan a tener restricciones espaciales.

---

## Mundo 4 — Negative

Introduce:

```text
Subtraction
Negative numbers
```

---

## Mundo 5 — Division

Introduce:

```text
Division
Filters
```

---

## Mundo 6 — Logic

Introduce sistemas de automatización:

```text
Comparator
Switch
Counter
```

Ejemplo:

```text
IF value > 10
    → OUTPUT A
ELSE
    → OUTPUT B
```

En este punto Numbly empieza a evolucionar desde puzzle matemático hacia puzzle de programación.

---

# 13. Tipos de niveles

La variedad no debe depender únicamente del número objetivo.

## Target

```text
Produce 64.
```

---

## Throughput

```text
Produce 64 a ≥ 10/s.
```

---

## Machine Limit

```text
Produce 64.

Máximo:
4 operadores.
```

---

## Space

Tablero reducido:

```text
8 × 8
```

---

## Budget

Cada componente tiene un coste.

```text
Budget: 500

Conveyor       2
Addition      40
Multiplication 80
```

---

## Multiple Outputs

```text
OUTPUT A → 12
OUTPUT B → 18
```

La misma fábrica debe producir ambos.

---

## Dynamic Target

El objetivo cambia durante la ejecución:

```text
12 → 24 → 36 → 48
```

La fábrica debe adaptarse automáticamente.

---

# 14. Challenge Levels

Cada mundo termina con un nivel especial.

No introduce necesariamente nuevas máquinas.

Combina los conocimientos anteriores.

Ejemplo:

## Challenge 1

**Produce 100 unidades de 24 en 60 segundos.**

Recursos:

```text
2
3
```

Restricciones:

```text
Máximo 6 operadores.
```

---

# 15. Metaprogresión

Debe mantenerse separada del balance competitivo de los puzzles.

Completar niveles proporciona:

### Bits

Los Bits pueden utilizarse inicialmente para:

* desbloquear mundos;
* skins;
* estilos visuales;
* efectos;
* temas del tablero;
* Quality of Life.

Evitar inicialmente mejoras como:

```text
+100% producción
```

porque podrían trivializar niveles diseñados manualmente.

---

# 16. Endless Mode — Posible contenido futuro

Modo separado de la campaña.

Aquí sí existe una fábrica persistente.

El jugador empieza pequeño y recibe objetivos progresivamente mayores.

Ejemplo:

```text
Produce 10
Produce 100
Produce 1K
Produce 1M
Produce 1B
...
```

Aquí podrían aparecer elementos incrementales tradicionales:

* upgrades permanentes;
* producción offline;
* prestige;
* multiplicadores;
* investigación.

Este modo **NO forma parte del MVP**.

---

# 17. UX móvil

La interacción debe ser extremadamente rápida.

## Construir

Arrastrar:

```text
●────────────●
```

crea automáticamente una línea de conveyors.

---

## Rotar

Tap sobre pieza seleccionada.

---

## Eliminar

Mantener pulsado + arrastrar.

---

## Undo / Redo

Siempre visibles.

Muy importante en un puzzle de construcción.

---

## Simulation Controls

```text
⏸    ▶    ▶▶    ▶▶▶
```

Velocidades:

```text
0×
1×
2×
4×
```

---

# 18. Dirección artística

Objetivo:

**Minimalista, limpia y extremadamente legible.**

Evitar una estética industrial demasiado cercana a otros factory games.

Una posible identidad es presentar el mundo como un **sistema digital abstracto**.

Los números son pequeñas entidades que recorren circuitos.

Referencias conceptuales:

```text
Circuit boards
Digital systems
Data flow
Minimal geometric UI
```

Cada operación debe identificarse inmediatamente por su símbolo:

```text
+
×
−
÷
```

La legibilidad tiene prioridad sobre el detalle artístico.

---

# 19. Audio

Minimalista.

Cada máquina puede producir pequeños sonidos sincronizados con su actividad.

Ejemplo:

```text
Source → tick
Operator → click
Output → pop
```

Una fábrica grande debería generar una especie de ritmo mecánico.

Completar un nivel necesita un feedback audiovisual especialmente satisfactorio.

---

# 20. Diferenciación

Numbly no pretende ser un sandbox de fábrica matemática.

Su identidad debe construirse alrededor de:

**Puzzles autocontenidos + restricciones + optimización + automatización.**

La progresión conceptual sería:

```text
MATEMÁTICAS
     ↓
LOGÍSTICA
     ↓
OPTIMIZACIÓN
     ↓
AUTOMATIZACIÓN
     ↓
PROGRAMACIÓN
```

La campaña por niveles es fundamental para esta identidad.

---

# 21. MVP

El primer objetivo NO es construir el juego completo.

Hay que responder una única pregunta:

> **¿Es divertido construir una máquina para producir un número y después optimizarla?**

Para comprobarlo, el MVP necesita solamente:

### Componentes

```text
Source
Conveyor
Addition
Multiplication
Output
```

### Sistemas

```text
Grid
Placement
Simulation
Level objectives
Reset
Undo
Win condition
```

### Contenido

**10 niveles.**

Sin:

* tienda;
* anuncios;
* login;
* cloud saves;
* prestige;
* endless;
* achievements;
* historia;
* cosméticos;
* leaderboards.

---

# 22. Primeros 10 niveles del prototipo

### Nivel 1

```text
Source: 1

Objetivo: 1
```

Enseña transporte.

---

### Nivel 2

```text
Sources: 1, 1

Objetivo: 2
```

Introduce suma.

---

### Nivel 3

```text
Sources: 2, 3

Objetivo: 5
```

Refuerza suma.

---

### Nivel 4

```text
Sources: 2, 2

Objetivo: 4
```

Introduce multiplicación.

---

### Nivel 5

```text
Sources: 2, 3

Objetivo: 6
```

Multiplicación básica.

---

### Nivel 6

```text
Sources: 2, 3

Objetivo: 8
```

Requiere encadenar operaciones.

Ejemplo:

```text
3 × 2 = 6
6 + 2 = 8
```

---

### Nivel 7

```text
Sources: 2, 3

Objetivo: 12
```

Primera solución con múltiples posibilidades.

---

### Nivel 8

```text
Objetivo: 12

Requirement:
≥ 4/s
```

Introduce throughput.

---

### Nivel 9

```text
Objetivo: 24

Máximo:
4 operadores
```

Introduce optimización.

---

### Nivel 10

```text
Objetivo: 48

≥ 5/s

Máximo:
5 operadores
```

Combina los conceptos anteriores.

---

# 23. Métricas que validar en el prototipo

Antes de añadir contenido hay que observar:

### Comprensión

¿El jugador entiende qué ocurre sin explicaciones largas?

### Construcción

¿Colocar cintas en móvil resulta agradable?

### Debugging

¿Puede identificar rápidamente por qué su fábrica no funciona?

### Satisfacción

¿Resulta agradable pulsar PLAY y observar funcionar la construcción?

### Optimización

¿Después de completar un nivel existe deseo de mejorar la solución?

Esta última pregunta es especialmente importante.

Si los jugadores completan un nivel y quieren inmediatamente pasar al siguiente, tenemos un puzzle competente.

Si además piensan:

> "Espera, creo que puedo hacerlo mejor..."

tenemos un núcleo con bastante más potencial.

---

# 24. Riesgos principales

## Riesgo 1 — Convertirse en ejercicio matemático

Mitigación:

Dar cada vez más importancia a logística, throughput y espacio.

---

## Riesgo 2 — Controles incómodos en móvil

Mitigación:

Prototipar interacción táctil antes de producir contenido.

---

## Riesgo 3 — Solución demasiado evidente

Mitigación:

Introducir restricciones y múltiples soluciones válidas.

---

## Riesgo 4 — Exceso de complejidad

Mitigación:

Introducir exactamente un concepto nuevo cada pocos niveles.

---

## Riesgo 5 — Parecido excesivo con otros factory games

Mitigación:

Construir identidad alrededor de:

* niveles autocontenidos;
* optimización;
* lógica;
* automatización;
* estética digital propia;
* restricciones específicas;
* estructura mobile-first.

---

# 25. Principios de alcance

Para mantener Numbly viable como proyecto indie:

**NO implementar una mecánica porque "quedaría bien".**

Cada sistema debe responder al menos una de estas preguntas:

1. ¿Crea decisiones interesantes?
2. ¿Permite crear nuevos tipos de puzzle?
3. ¿Mejora significativamente la experiencia de construcción?
4. ¿Refuerza la progresión?

Si la respuesta es no, queda fuera.

---

# 26. Objetivo de la primera versión jugable

La primera milestone debería ser extremadamente pequeña:

```text
Tablero 10×10

Source 2
Source 3

Conveyor
Addition
Multiplication
Output

Objetivo:
Produce 12
```

El jugador debe poder:

```text
Construir
   ↓
Pulsar PLAY
   ↓
Ver números moverse
   ↓
Transformarlos
   ↓
Entregar 12
   ↓
Completar nivel
```

Si conseguir que **ese único nivel** resulte agradable requiere cambiar el diseño, se cambia antes de construir cualquier sistema adicional.

---

# 27. North Star

La experiencia que Numbly debe perseguir puede resumirse en:

> **"Yo construí esta máquina."**

No:

> "Conseguí el número correcto."

El número proporciona el problema.

**La máquina construida por el jugador es el juego.**
