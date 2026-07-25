#eSports Deck (en Progreso)

![Flutter](https://img.shields.io/badge/Made_with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Status](https://img.shields.io/badge/Status-En_Desarrollo-orange?style=for-the-badge)

**eSports Deck** es un juego de gestión y cartas coleccionables que traslada el conocimiento táctico de los deportes electrónicos a una experiencia de estrategia pura. No controlas el *aim*, controlas las decisiones. Arma tu roster, abre sobres, gestiona la economía y llévate el trofeo a casa.

---

## Características Principales

### Coleccionismo y Economía
* **Apertura de Sobres:** Consigue sobres Básicos y Premium usando la moneda del juego.
* **Rarezas:** Colecciona jugadores en calidad *Común, Rara, Épica y Legendaria/MVP*.
* **Mercado (Quick Sell):** Vende las cartas repetidas para recuperar economía y buscar mejores sobres.

### Profundidad Estráctica
No basta con tener cartas de OVR alto. Las partidas se ganan en el **Draft**:
* **Sistema de Química:** Combina jugadores con balance de roles, misma región o mismo equipo oficial para obtener hasta +3 puntos de bonificación.
* **Sinergia Mapa/Agente:** Asigna los agentes correctos dependiendo del mapa aleatorio que toque para obtener ventajas ocultas en el servidor.
* **Momentum y Tilt:** Un sistema psicológico en vivo. Si tu equipo gana 3 rondas seguidas, se encienden (+1 AIM/MENTAL). Si pierden 3, entran en *Tilt* (a menos que pidas un Timeout táctico).

### Modos de Juego
1. **Torneo (Doble Eliminación):** Formato clásico de eSports (Upper/Lower Bracket). Llévate el premio mayor y sobres exclusivos.
2. **Simulación Real (13 Rondas):** Partidas completas donde tomarás decisiones en vivo: ¿Haces un Eco o fuerzas compra? ¿Quién toma el duelo de AIM en el Clutch?
3. **Partida Rápida (Arcade):** Ideal para farmear monedas en sesiones de 1 minuto.

---

## Roadmap del Proyecto

Actualmente, el motor lógico del juego está diseñado para simular competiciones Hero-Shooter tácticos, pero el ecosistema está construido para expandirse a otras disciplinas.

- [x] **Fase 1:** Sistema Core, UI Base y Motor de Duelos (Enfoque: VALORANT).
- [ ] **Fase 2:** Integración de Base de Datos, Mercado y Sobres.
- [ ] **Fase 3:** Expansión de motor a economía de CS2 (Counter-Strike 2).
- [ ] **Fase 4:** Expansión a físicas/mecánicas de Rocket League.

---

## Tecnologías
Este proyecto está siendo desarrollado usando **Flutter** para lograr animaciones de cartas y UI fluidas, y **Supabase** para gestionar el inventario, los perfiles y el balance de la economía en la nube.

> **Nota:** Este repositorio es un proyecto de desarrollo independiente de **TecniStudio**.
