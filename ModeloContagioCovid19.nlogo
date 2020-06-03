breed [personas persona]

patches-own [bloqueo]

personas-own [estadoContagio rangoEdad nivelEnfermedadPreexistente probabilidadMuerte tiempoConCovid vivo? ubicado? mover?]

globals [colorContagiado diasTranscurridos tiempoRecuperacionContagio xcorFranja]

;------------------------------------------------------------------

to ConstruirMundo

  ifelse(escenario = "Libertad total")
  [
    ask patches [set pcolor white]
  ]
  [
    ifelse(escenario = "Cuarentena")
    [
      ask patches [set pcolor white set bloqueo 0]
      ask patches with [pxcor = xcorFranja] [set pcolor black set bloqueo 1] ;  bloqueo ---> 0: las personas se pueden mover    1: las personas no se pueden mover
    ]
    [
      ifelse(escenario = "Aislamiento moderado")
      [ask patches [set pcolor white]]
      [
        if(escenario = "Aislamiento exhaustivo")
        [ask patches [set pcolor white]]
      ]
    ]
  ]
end

to CrearPersonas [cantidadPersonas]

  let cantidadJovenes (cantidadPersonas * (41 / 100)) ; 41% de la poblacion es joven
  let cantidadAdultos (cantidadPersonas * (42 / 100)) ; 42% de la poblacion es adulta
  let cantidadAncianos (cantidadPersonas * (17 / 100)) ; 17% de al poblacion es anciana
  let cantidadPersonasEnfermas (cantidadPersonas * (15 / 100)) ; 15% de la poblacion tiene algun nivel de enfermedad
  let nivelEnfermedad [2 3 4]

  create-personas cantidadPersonas
  [
    set estadoContagio 1;  estadoContagio -----> 0: indefinido   1: vulnerable   2: contagiado   3: recuperado
    set rangoEdad 0;       rango edad ---------> 0: indefinido   1: joven        2: adulto       3: anciano
    set probabilidadMuerte 0
    set nivelEnfermedadPreexistente 1;  nivelEnfermedadPreexistente ----> 0: indefinido   1: inexistente   2: leve   3: medio   4: terminal
    set tiempoConCovid 0
    set vivo? true
    set ubicado? false
    set mover? true

    set color green
    setxy (random-xcor) (random-ycor)
  ]

  ask personas
  [
    if((patch-ahead 1 = nobody) or (([bloqueo] of patch-here) = 1)); esto lo que hace es verificar si se encentran en una parcela de la que no pueden moverse y reposiciona a las personas
    [setxy random-xcor random-ycor]
  ]

  ask n-of cantidadJovenes personas with [rangoEdad = 0]
  [
    set shape "person student"
    set rangoEdad 1
    set probabilidadMuerte 3 ; ----> Los jovenes tienen 3% de probabilidades de morir
  ]

  ask n-of cantidadAdultos personas with [rangoEdad = 0]
  [
    set shape "persona adulta"
    set rangoEdad 2
    set probabilidadMuerte 7 ; ----> Los adultos tienen 7% de probabilidades de morir
  ]

  ask n-of cantidadAncianos personas with [rangoEdad = 0]
  [
    set shape "persona anciana"
    set rangoEdad 3
    set probabilidadMuerte 30 ; ----> Los ancianos tienen un 30% de probabilidades de morir
  ]

  ;-------------- asignacion de enfermedades-----------------------------------

  ask n-of cantidadPersonasEnfermas personas
  [
    set nivelEnfermedadPreexistente (one-of nivelEnfermedad) ; Al porcentaje de la población que está enferma se le asígna un nivel de enfermedad al azar
  ]

  ;-----------------------------------------------------------------------------

  ask one-of personas [set estadoContagio 2 set color colorContagiado]
end

to PosicionarPersonas [porcentajeDesobedientes]
  let xcorDesobedientes xcorFranja
  let coordenadasXObedientes (range (xcorDesobedientes + 2) max-pxcor)
  let coordenadasXDesobedientes (range min-pxcor (xcorDesobedientes))
  let cantidadDesobedientes (poblacionTotal * (porcentajeDesobedientes / 100))
  let cantidadObedientes (poblacionTotal - cantidadDesobedientes)

  if(escenario = "Cuarentena")
  [
    ask n-of cantidadObedientes personas with [ubicado? = false] [ setxy (one-of coordenadasXObedientes) (random-ycor) set ubicado? true]
    ask n-of cantidadDesobedientes personas with [ubicado? = false] [setxy (one-of coordenadasXDesobedientes) (random-ycor) set ubicado? true]
    ask personas with [estadoContagio = 2] [setxy one-of coordenadasXDesobedientes random-ycor]
  ]
end

to EstablecerProbabilidadMuerte
  ask personas with [nivelEnfermedadPreexistente = 2] [set probabilidadMuerte (probabilidadMuerte + 5)] ;Las personas que tengan un nivel de enfermedad leve se le suma un 5% en probabilidad de morir

  ask personas with [nivelEnfermedadPreexistente = 3] [set probabilidadMuerte (probabilidadMuerte + 10)] ;Las personas que tengan un nivel de enfermedad medio se le suma un 10%

  ask personas with [nivelEnfermedadPreexistente = 4] [set probabilidadMuerte (probabilidadMuerte + 15)] ;Las personas que tengan un nivel de enfermedad terminal se le suma un 15%
end

to EstablecerMovimiento [porcentajePersonasMovimiento]
  let cantidadPersonasMovimiento 0

  ifelse(escenario = "Aislamiento moderado")
  [
    set cantidadPersonasMovimiento (poblacionTotal * (porcentajePersonasMovimiento / 100))
    ask personas with [estadoContagio = 1] [set mover? false]
    ask n-of cantidadPersonasMovimiento personas with [estadoContagio = 1] [set mover? true]
  ]
  [
    if(escenario = "Aislamiento exhaustivo")
    [
      set cantidadPersonasMovimiento (poblacionTotal * ((floor (porcentajePersonasMovimiento / 2)) / 100))
      ask personas with [estadoContagio = 1] [set mover? false]
      ask n-of cantidadPersonasMovimiento personas with [estadoContagio = 1] [set mover? true]
    ]
  ]

end

to MoverPersonas

  ifelse(escenario = "Cuarentena"); movimiento para las personas que se encuentran en cuarentena y que no pueden pasar mas allá de la franja
  [
    ask personas with [mover? = true]
      [
        ifelse(([bloqueo] of patch-here = 0) and (can-move? 0.5))
        [rt (random 50 - random 50) fd 0.1]
        [rt 180 fd 0.2]
      ]
  ]
  [
    ask personas with [mover? = true]
    [
      ifelse(can-move? 0.5)
      [rt (random 50 - random 50) fd 0.1]
      [rt 180]
    ]
  ]

end

to Contagiar
  ask personas with [(estadoContagio = 2) and (vivo? = true)] [ask personas in-radius 0.5 with [(estadoContagio = 1) and (vivo? = true)] [set estadoContagio 2 set color colorContagiado]]
end

to RevisarEstadoPersonas
  let numeroRandom 0
  set numeroRandom (random 100)
  let tiempoRecuperacionJovenes (tiempoRecuperacionContagio)
  let tiempoRecuperacionAdultos ((2 * 24) + tiempoRecuperacionContagio) ; A los adultos se les suma dos dias en el tiempo de recuperacion
  let tiempoRecuperacionAncianos ((5 * 24) + tiempoRecuperacionContagio) ; A los ancianos se les suma cinco dias en el tiempo de recuperacion

  ;Revision jovenes
  ask personas with [(estadoContagio = 2) and (vivo? = true) and (rangoEdad = 1)]
  [
    ifelse(tiempoConCovid = tiempoRecuperacionJovenes)
    [
      ifelse (member? numeroRandom (range probabilidadMuerte))
      [
        set vivo? false
        hide-turtle
        set estadoContagio 0
      ]
      [
        set estadoContagio 3
        set color turquoise
      ]
    ]
    [
      set tiempoConCovid (tiempoConCovid + 1)
    ]
  ]


  ;Revision adultos
  ask personas with [(estadoContagio = 2) and (vivo? = true) and (rangoEdad = 2)]
  [
    ifelse(tiempoConCovid = tiempoRecuperacionAdultos)
    [
      ifelse (member? numeroRandom (range probabilidadMuerte))
      [
        set vivo? false
        hide-turtle
        set estadoContagio 0
      ]
      [
        set estadoContagio 3
        set color turquoise
      ]
    ]
    [
      set tiempoConCovid (tiempoConCovid + 1)
    ]
  ]


  ;Revision ancianos
  ask personas with [(estadoContagio = 2) and (vivo? = true) and (rangoEdad = 3)]
  [
    ifelse(tiempoConCovid = tiempoRecuperacionAncianos)
    [
      ifelse (member? numeroRandom (range probabilidadMuerte))
      [
        set vivo? false
        hide-turtle
        set estadoContagio 0
      ]
      [
        set estadoContagio 3
        set color turquoise
      ]
    ]
    [
      set tiempoConCovid (tiempoConCovid + 1)
    ]
  ]

end

to ActualizarMuro [diasAislamiento]
  let ticksAislamiento (diasAislamiento * 24) ; como el dia dura 24 ticks se multiplica por el numero de días

  if(escenario = "Cuarentena")
  [
    if (ticks > ticksAislamiento)
    [
      ask patches with [bloqueo = 1]
      [
        if(any? patches with [bloqueo = 1])
        [set bloqueo 0 set pcolor white]
      ]
    ]
  ]
end

to ActualizarDiasTranscurridos
  if( (ticks > 1) and ((ticks mod 24) = 0) )
  [set diasTranscurridos (diasTranscurridos + 1)]
end


to Ejecutar
  if( (count personas with [estadoContagio = 2]) = 0)
  [stop]

  MoverPersonas
  Contagiar
  RevisarEstadoPersonas
  ActualizarMuro 30 ;----> x dias de aislamiento
  ActualizarDiasTranscurridos
  tick
end

to setUp
  ca
  reset-ticks
  set-default-shape personas "person"
  set colorContagiado pink
  set diasTranscurridos 0
  set tiempoRecuperacionContagio 336 ; 336 ticks son 14 días que tarda la recuperacion de una persona que ha estado contagiada
  set xcorFranja ceiling (((world-width / 2) / 3) * -1)
  ConstruirMundo
  CrearPersonas poblacionTotal
  PosicionarPersonas 10 ;----> el 10% de la poblacion es desobediente
  EstablecerProbabilidadMuerte
  EstablecerMovimiento 25 ;----> porcentaje de personas que se pueden mover en aislamiento moderado, si el exhaustivo va a ser la mitad
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
640
441
-1
-1
12.8
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
34
21
92
54
NIL
setUp
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
30
77
116
110
NIL
Ejecutar
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
9
137
181
170
poblacionTotal
poblacionTotal
0
1000
500.0
10
1
NIL
HORIZONTAL

MONITOR
690
15
821
60
Personas vulnerables
count personas with [estadoContagio = 1]
17
1
11

MONITOR
691
71
825
116
Personas contagiadas
count personas with [estadoContagio = 2]
17
1
11

MONITOR
891
217
1003
262
Días transcurridos
diasTranscurridos
17
1
11

PLOT
197
462
610
652
Grafico
dias
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Personas contagiadas" 1.0 0 -2064490 true "" "plotxy (diasTranscurridos) (count personas with [ (estadoContagio = 2) and (vivo? = true)])"
"Personas vulnerables" 1.0 0 -13840069 true "" "plotxy (diasTranscurridos) (count personas with [(estadoContagio = 1) and (vivo? = true)])"
"Personas recuperadas" 1.0 0 -14835848 true "" "plotxy (diasTranscurridos) (count personas with [estadoContagio = 3 and (vivo? = true)])"

CHOOSER
13
193
188
238
escenario
escenario
"Libertad total" "Cuarentena" "Aislamiento moderado" "Aislamiento exhaustivo"
3

MONITOR
689
133
825
178
Personas recuperadas
count personas with [estadoContagio = 3]
17
1
11

MONITOR
689
210
826
255
Personas muertas
count personas with [(vivo? = false) and (hidden? = true)]
17
1
11

MONITOR
891
19
983
64
Jovenes vivos
count personas with [rangoEdad = 1 and (vivo? = true)]
17
1
11

MONITOR
889
84
976
129
Adultos vivos
count personas with [rangoEdad = 2 and (vivo? = true)]
17
1
11

MONITOR
889
154
984
199
Ancianos vivos
count personas with [(rangoEdad = 3) and (vivo? = true)]
17
1
11

MONITOR
1009
18
1104
63
Jovenes muertos
count personas with [rangoEdad = 1 and (vivo? = false)]
17
1
11

MONITOR
1011
86
1114
131
Adultos muertos
count personas with [rangoEdad = 2 and (vivo? = false)]
17
1
11

MONITOR
1008
154
1119
199
Ancianos muertos
count personas with [(rangoEdad = 3) and (vivo? = false)]
17
1
11

MONITOR
694
278
829
323
Personas vivas
count personas with [vivo? = true and (hidden? = false)]
17
1
11

PLOT
640
460
1075
656
Personas muertas
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Jovenes muertos" 1.0 0 -2674135 true "" "plotxy (diasTranscurridos) (count personas with [(vivo? = false) and (hidden? = true) and (rangoEdad = 1)])"
"Adultos muertos" 1.0 0 -6459832 true "" "plotxy (diasTranscurridos) (count personas with [(vivo? = false) and (hidden? = true) and (rangoEdad = 2)])"
"Ancianos muertos" 1.0 0 -13840069 true "" "plotxy (diasTranscurridos) (count personas with [(vivo? = false) and (hidden? = true) and (rangoEdad = 3)])"

MONITOR
1164
22
1311
67
Personas en movimiento
count personas with [mover? = true and vivo? = true and hidden? = false]
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

persona adulta
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

persona anciana
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 90 135 120 135
Line -16777216 false 105 120 120 120
Line -16777216 false 180 120 195 120
Line -16777216 false 180 135 210 135
Line -16777216 false 90 150 105 165
Line -16777216 false 225 165 210 180
Line -16777216 false 75 165 90 180
Line -16777216 false 210 150 195 165
Line -16777216 false 180 105 210 180
Line -16777216 false 120 105 90 180
Line -16777216 false 150 135 150 165
Polygon -6459832 true false 105 30 104 44 195 30 185 10 173 10 166 1 138 -1 111 3 109 28

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
