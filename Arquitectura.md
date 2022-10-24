# Arquitectura

Este documento tiene como objetivo establecer las responsabilidades y funcionalidades básicas de cada entidad de la aplicación, como así también su flujo.

## Presentación de Entidades

A continuación se detallan las entidades del modelo.

### Client

* Renderiza la GUI al cliente y recibe sus inputs, a través de la consola.
* Representa al cliente dentro del back del GameEngine.
* Existirá uno por cada cliente conectado al juego.

### Directory

* Interactúa con el cliente para asignarlo a una nueva GameSession
* Interactúa con las GameSession para determinar

### GameSession

* Responsable de la partida actual de N jugadores.
* Administra los R rooms que contienen el mapa a ser jugado, interactuando con entidad Room.

### Room

* Ejecuta la lógica del juego interactuando con todas las entidades presentes en una habitación.
* Interactua con Client y con Enemy





