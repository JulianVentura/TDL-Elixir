# Arquitectura

Este documento tiene como objetivo establecer las responsabilidades y funcionalidades básicas de cada entidad de la aplicación, como así también su flujo.

## Presentación de Entidades

A continuación se detallan las entidades del modelo.

### Client

* Renderiza la GUI al cliente y recibe sus inputs, a través de la consola.
* Representa al cliente dentro del back del GameEngine.
* Existirá uno por cada cliente conectado al juego.

### GameMaker

* Interactúa con el cliente para asignarlo a una nueva GameSession
* Interactúa con las GameSession

### GameSession

* Responsable de la partida actual de N jugadores.
* Administra los R rooms que contienen el mapa a ser jugado, interactuando con entidad Room.

### Room

* Ejecuta la lógica del juego interactuando con todas las entidades presentes en una habitación.
* Interactua con Client y con Enemy



## Flujo de la Aplicación

1. Usuario lanza el aplicativo cliente.
   1. Se conecta la máquina del usuario como nuevo nodo al servidor
   2. Se instancia (en la máquina del usuario) una instancia Cliente.
2. Cliente solicita al usuario si desea iniciar una nueva partida
   1. Puede ser una generada por el sistema o una por password
3. Cliente envía un mensaje a GameMaker para iniciar una nueva partida
4. Si se proporcionó una password para la partida, se asigna al cliente a dicha GameSession
5. Si no se proporcionó password GameMaker detecta si existe algún GameSession aguardando por completar jugadores (hay una cantidad mínima?)
   1. Si la hay entonces lo asigna a dicha GameSession (random entre todas las que haya en espera)
   2. Caso contrario, spawnea un nuevo proceso GameSession y asigna al cliente a este.
6. Cliente le envía un mensaje a la GameSession solicitando ingreso
   1. La GameSession puede rebotarlo en caso de que la partida ya haya comenzado.
7. Usuarios esperan en la GameSession hasta que todos elijan un mapa (de 2 o 3 opciones de mapas)
8. GameSession inicializa el mapa a partir del spawneo de N procesos Room (que deberían poder estar en distintas máquinas) y les informa a los clientes cuál es la primera sala.
9. Cada Room podrá comunicar a los clientes con las otras Rooms con las cuales se conecta (entrada y salida).



## Escalado del Sistema

A continuación se detalla cómo el sistema es capaz de escalar en múltiples computadoras ante la demanda de usuarios.

El sistema podrá escalar a partir de la creación de nuevos procesos en los distintos nodos que lo componen.

La abstracción por la cuál se facilitarán el escalado queda aún por determinar, pero se presupone que se tratará de un middleware que permita abstraer de la lógica de distribución al momento de crear un nuevo proceso. Esto es:

* Se le indicará que se desea generar un nuevo proceso de un módulo X con Y argumentos, incluido posiblemente un nombre.
* Se retornará una dirección de dicho proceso

Para que esto tenga sentido, el sistema debería ser capaz de escalar sus recursos de forma dinámica (elasticidad), para lo cuál se deberá emplear alguna forma de sumar nodos al sistema. Esta incorporación podría ser implementada en el mismo middleware de balanceo, a partir de la biblioteca de monitoreo de `:net_kernel`. 

Cuando se desea ingresar un nuevo nodo a la red, se ejecuta un aplicativo servidor que se conectará a la red del sistema bajo algún nombre determinado (queda por definir cómo asignar un nombre que no colisione), lo que resultará en la detección por parte del middleware quien lo adoptará como nuevo recurso.


## Tolerancia a Fallos

A continuación se detalla bajo qué situaciones el sistema es capaz de recuperarse de un fallo y cuál es su estrategia para conseguir esto.

En Elixir es posible definir procesos supervisores que se encargarán de volver a levantar procesos caídos que se encuentren bajo su supervisión. Si a esto se le suma un almacenamiento estable, es decir, un almacenamiento persistente, accesible por todos los procesos del sistema y tolerante a fallos, entonces la tarea de componer un sistema tolerante a fallos se vuelve más sencilla.

Los desafíos a resolver son:

* Cómo proveer una identidad a los procesos que mantienen estado (GameSession, Room, GameMaker, etc.)
  * Con esto nos referimos a un nombre a partir del cuál sean unívocamente identificados en el sistema
  * Idealmente también debería servirnos para utilizar como address al realizar una comunicación
* Cómo asignar esa identidad (y garantizar que sea única) a un proceso
* Cómo serializar y recuperar el estado del proceso (y los demás procesos) caído
* Cómo garantizar la transaccionalidad del estado (i.e. que no suceda que ante una caída el estado global del sistema quede inválido)


Desde ya que estos desafíos pueden atacarse tomando distintas hipótesis que los simplifiquen, o directamente evitándolos.



## Herramientas Externas

Se utilizará una BDD Redis (o un mock de la misma) como almacenamiento estable, con el objetivo de facilitar la resiliencia de las entidades del sistema.



## Preguntas

1. Cómo hacer un supervisor distribuído? Es decir, que supervise procesos que corren en distintos nodos y permita levantarlos en dichos (u otros) nodos. 
