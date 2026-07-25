# DOCUMENTO DE DISEÑO DE JUEGO (GDD): eSports Deck - VALORANT

## 1. SISTEMA DE CARTAS Y RAREZAS
Cada carta representa a un jugador profesional de eSports y contiene la siguiente información clave que afecta directamente al gameplay:

### A. Anatomía de la Carta (Jugador)
* **OVR (Overall Rating):** La media general de la carta. Sirve para el emparejamiento visual y el cálculo rápido del Poder de Equipo.
* **Atributos Base (Estadísticas para duelos y eventos):**
  * **AIM (Puntería):** Clave para duelos directos y primeras sangres.
  * **MENTAL (Mentalidad):** Resistencia al Tilt y aguante bajo presión.
  * **IMPACT (Impacto):** Capacidad para abrir rondas y generar ventajas numéricas.
  * **UTI (Utilidad):** Habilidad para usar herramientas del agente en ejecuciones.
  * **REA (Reacción):** Velocidad para responder a situaciones inesperadas.
  * **CLUTCH:** Determinante para ganar rondas en desventaja numérica (1v2, 1v3).
* **Rol Principal:** DUE (Duelista), INI (Iniciador), CON (Controlador), CEN (Centinela).
* **Metadatos de Química:** Región (ej. Americas, EMEA, Pacific) y Equipo Oficial (ej. Leviatán, Sentinels, Fnatic).

### B. Niveles de Rareza
* **Común:** OVR menor a 75. Cartas base iniciales.
* **Rara:** OVR entre 75 y 82. Jugadores de rotación.
* **Épica:** OVR entre 83 y 89. Estrellas de la liga.
* **Legendaria / MVP:** OVR 90+. Los mejores del mundo. Incluyen animaciones especiales de revelación.

---

## 2. ECONOMÍA DEL JUEGO Y SISTEMA DE SOBRES (PACKS)
La economía está diseñada para equilibrar el tiempo de juego, la gratificación del coleccionismo y prevenir la inflación dentro del juego.

### A. Probabilidades de Sobres (Drop Rates)
A mayor rareza de la carta, menor es la probabilidad de obtención en sobres para mantener el valor táctico y la emoción.

* **Sobre Básico (Cuesta: 1000 Monedas | Contiene: 2 Cartas)**
  * **Común:** 70% de probabilidad por carta.
  * **Rara:** 24% de probabilidad por carta.
  * **Épica:** 5% de probabilidad por carta.
  * **Legendaria:** 1% de probabilidad por carta.

* **Sobre Premium (Cuesta: 5000 Monedas | Contiene: 2 Cartas)**
  * *Garantía:* Asegura al menos 1 carta Épica o superior.
  * **Común:** 40%
  * **Rara:** 40%
  * **Épica:** 17%
  * **Legendaria:** 3%

### B. Venta Rápida de Cartas Repetidas (Quick Sell)
Permite al jugador descartar cartas repetidas o no deseadas a cambio de recuperar una fracción controlada de monedas:
* Vender carta **Común:** 100 Monedas
* Vender carta **Rara:** 250 Monedas
* Vender carta **Épica:** 1000 Monedas
* Vender carta **Legendaria:** 5000 Monedas

### C. Recompensas por Jugar (Ingresos)
* **Modo Partida Rápida (1 Minuto):**
  * Victoria: 150 Monedas
  * Derrota: 50 Monedas
* **Modo Partida Completa (13 Rondas):**
  * Victoria: 800 Monedas
  * Derrota: 300 Monedas
* **Modo Torneo (Campeonato):**
  * Campeón: 5000 Monedas + 1 Sobre Premium Gratis

### D. Eventos Especiales
* **Sobre Champions (Cuesta: 6000 Monedas):** Disponible por tiempo limitado durante torneos internacionales. Contiene un 10% de probabilidad de soltar cartas de edición especial.

---

## 3. MODOS DE JUEGO PRINCIPALES

### A. Modo Torneo (Doble Eliminación)
* **Estructura:** Llaves organizadas con Upper Bracket (Ganadores) y Lower Bracket (Perdedores). Perder en Upper te manda a Lower; perder en Lower elimina al equipo.
* **Fase previa (Draft):** Elección obligatoria de 5 cartas titulares desde el inventario.
* **Formato:** Encuentros al mejor de 5 rondas (BO5).
* **Recompensas:** Gran cantidad de monedas y Sobre Premium exclusivo al ganar la final.

### B. Modo Partida Rápida (Arcade)
* **Estructura:** Sesiones instantáneas de ~1 minuto.
* **Formato:** Partidas al mejor de 5 rondas sin eventos en vivo complejos. Resolución directa comparando estadísticas globales + RNG controlado.
* **Recompensas:** Monedas bajas, ideal para farmeo rápido.

### C. Modo Partida Completa (Simulación Real)
* **Estructura:** Simulación competitiva hasta alcanzar 13 rondas ganadas.
* **Próroga / Overtime:** En empate 12-12, la partida se extiende hasta que un equipo logre diferencia de 2 rondas.
* **Eventos dinámicos en vivo:**
  1. **Duelo 1v1 (Adivinar el AIM):** Valores de AIM ocultos. El usuario elige quién ganaría el duelo; si acierta con una carta inferior, se activa una jugada táctica por la espalda.
  2. **Decisión Económica (Forzar o Ahorrar):** En ronda 2 tras ganar la ronda de pistolas, se presenta la opción de Forzar compra con un 70% de éxito o hacer Eco para asegurar la ronda 3. Si se presiona Forzar e igualmente pierdes la ronda, la ronda 3 tiene un 80% de probabilidad de perderse.
  3. **Situación de Clutch (1v2 / 1v3):** En desventaja, se oculta la stat de CLUTCH y el jugador debe decidir a qué rival enfrentarse primero.

---

## 4. MOTOR DE COMBATE Y PROBABILIDADES
* **Poder de Equipo (Team Rating):** Promedio de las estadísticas y OVR del roster seleccionado.
* **Fórmula de Resolución por Ronda:**
  `Puntuación de Rendimiento = Atributo Seleccionado + Factor de Suerte Random(-5 a +5)`
* **Resultado:** El equipo con mayor Puntuación de Rendimiento gana el punto de la ronda.

---

## 5. FLUJO DE INICIO DE PARTIDA (FASES PREVIAS)
1. **Selección de Mapa Aleatorio:** Sale un mapa oficial (ej. Ascent, Lotus, Bind, Haven).
2. **El Draft de Roster (5 Jugadores):** Selección de las 5 cartas cubriendo roles:
   * DUE: Duelista
   * INI: Iniciador
   * CON: Controlador
   * CEN: Centinela
   * FLX: Comodín / Flex
3. **Selección de Agentes:** Se asigna un agente de Valorant a cada jugador seleccionado.

---

## 6. EL SISTEMA DE QUÍMICA / SINERGIA (HASTA 3 PUNTOS POR CARTA)
Cada jugador puede acumular hasta 3 puntos de química que aumentan sus atributos en partida:
* **Criterio A - Balance de Roles (+1 Punto):** Si hay al menos 1 DUE, 1 INI, 1 CON y 1 CEN en el equipo.
* **Criterio B - Coincidencia de Región (+1 Punto):** Si 2 o más jugadores son de la misma región (ej. Americas).
* **Criterio C - Coincidencia de Equipo (+1 Punto):** Si 2 o más jugadores pertenecen al mismo equipo oficial (ej. Sentinels). (Al ser del mismo equipo, automáticamente comparten región, asegurando 2 puntos).

---

## 7. SINERGIA DE AGENTE Y MAPA (BONIFICACIÓN TÁCTICA)
* **Mecánica:** Si el agente asignado a una carta es considerado un comfort pick o ideal para el mapa sorteado (ej. Sova en Ascent), la carta recibe una bonificación oculta de +1 extra en las fórmulas de rendimiento de cada ronda.

---

## 8. EL SISTEMA DE MOMENTUM Y TILT (DINÁMICA DE PARTIDA)
* **Momentum (Racha positiva):** Ganar 3 rondas seguidas otorga un buff de +1 en AIM y MENTAL.
* **Tilt (Racha negativa):** Perder 3 rondas seguidas aplica un debuff de -1 en MENTAL.
* **El Timeout (Pausa Táctica):** Habilidad de 1 solo uso por partido. Permite al usuario pausar cuando está en Tilt, frenar la racha rival, restablecer la MENTAL a cero y cambiar el estilo de juego (de "Presión" a "Juego Lento") por las siguientes 3 rondas.

---

## 9. PANTALLA POST-PARTIDO (RESUMEN DE MÁNAGER)
Al finalizar el encuentro, se presenta una pantalla de analista oficial estilo VCT:
* **MVP del Partido:** La carta de mejor rendimiento general.
* **Clutch Master:** La carta que ganó más duelos en desventaja.
* **Reporte Económico:** Monedas ganadas, experiencia adquirida y sobres obtenidos.

---
*(Nota: Bases de datos y mecánicas en fases futuras para expansiones como Counter-Strike 2 y Rocket League se adaptarán sobre este core de motor de rondas y estadísticas).*
