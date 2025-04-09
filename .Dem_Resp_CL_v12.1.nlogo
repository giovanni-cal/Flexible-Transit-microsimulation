extensions [ gis nw ]  ; GIS extension for geographical data and nw for network analysis

; Global variables declaration
globals
[
  energy-consumption      ; Energy consumption rate based on vehicle type
  max-walk-dist           ; Maximum walking distance for users
  start-sim-time end-sim-time  ; Start and end times for simulation
  service-type            ; Type of service: FRT (Fixed Route Transit) or DRT (Demand Responsive Transit)
  min-cost-match          ; Minimum cost for matching users to vehicles
  reject-flag             ; Flag to indicate if a request is rejected
  time                    ; Current simulation time
; lists
  color-list              ; List of colors for different lines
  demand-coeff-list       ; List of demand coefficients for different times of day
  vehicle-list            ; List of vehicles
  trip-OD-list            ; List of origin-destination trips
  line-name-list          ; List of line names
  line-trip-list          ; List of trips for each line
  pax-load-profile        ; Passenger load profile [pickups, dropoffs, onboard]
  solution-list           ; List of solutions for matching
  ;[0: [0.0:min-cost-match [ 1.0:[lineID, tripNUM] 1.1:[n1 n2] ] [ 2.0 ... 2.1 ... ] ], [1: [1.0 min-cost-match, [ ... ], [ ... ], ...] ... ]
  stop-link-list-1 stop-link-list-2  ; Lists of links between stops
; coefficients and input parameters
  cost-km                 ; Cost per kilometer (€/veh-km)
  cost-h                  ; Cost per hour (€/veh-h)
  dt                      ; Delta-time in seconds [0, 60]
  m/p                     ; Length of one patch in meters
  ped-speed               ; Pedestrian walking speed
  prob-1-pax              ; Probability of having one passenger per request
  tau-pax tau-stop tau-terminal  ; Time delays for passengers, stops, and terminals
  travel-time-threshold   ; Maximum travel time user tolerance
  vehicle-capacity        ; Capacity of vehicles
  VoT                     ; Value of Time (€/h)
  wgt-walk wgt-wait wgt-ride wgt-oper  ; Weights for different travel components
; output indicators
  time-avg-commercial-speed  ; Average commercial speed over time
  time-avg-load-factor       ; Average load factor over time
  total-energy-use           ; Total energy used
  total-travel-distance      ; Total distance traveled
  total-travel-time          ; Total travel time
  tot-n-of-trips             ; Total number of trips
  n-of-accepted              ; Number of accepted trip requests
  n-of-delayed               ; Number of delayed trips
  n-of-rejected              ; Number of rejected trip requests
  n-of-stops                 ; Number of stops
  n-of-transfers             ; Number of transfers between vehicles
  n-tot-users                ; Total number of users
  n-tot-walking              ; Total number of walking users
; for network editing
  clicked-node               ; Node that was clicked on
  first-node second-node     ; First and second nodes for link creation
  flag-link                  ; Flag for link creation
  mouse-clicked              ; Keeps track of click-and-hold
  mouse-double-click         ; True if two mouse clicks are registered in a quarter second
]

; Patch properties
patches-own
[ IDsez ]  ; ID of the section/zone for each patch

; Node breed and properties
breed [nodes node]
nodes-own [ ID ]  ; ID for network nodes

; Street links and properties
directed-link-breed [streets street]
streets-own [
  street-length   ; Length of the street
  maxspeed        ; Maximum speed allowed on the street
]

; Stop node breed and properties
breed [ stop-nodes stop-node ]
stop-nodes-own [
  ID s-line-list         ; ID and list of lines serving this stop
  occupancy bookings n-boarded n-alighted  ; Passenger statistics
  is-drt-stop?           ; Whether this is a demand-responsive transit stop
]

; Vehicle breed and properties
breed [vehicles vehicle]
vehicles-own [
  vehID lineID linename terminal  ; ID, line, and terminal info
  v-trip-list              ; List of trips: [line_ID, trip_NUM, departure_time]
  n-of-trips               ; Number of trips completed
  heading-flag stop-flag move-flag terminal-flag  ; Status flags
  count-streets current-street  ; Street tracking
  count-stops next-stop last-stop  ; Stop tracking
  i-stop-time stop-time tot-stop-time  ; Time spent at stops
  on-board-list            ; List of passengers on board
  stop-list                ; List of scheduled stops [stop_i, exp-time_i]
  street-list              ; List of streets on route
  booking-list             ; List of bookings
  travel-distance path-time commercial-speed  ; Travel statistics
  travel-time-list travel-distance-list  ; Lists for travel time and distance
]

; User breed and properties
breed [ users user ]
users-own [
  group-size request-time             ; Size of the user group and request time
  origin destination                  ; Origin and destination
  latest-pick-up-time latest-drop-off-time  ; Time constraints
  origin-stop destination-stop transfer-stop  ; Stops for the trip
  user-tripID-list                    ; List of trip IDs [line_ID, trip_num]
  stop-expected-time                  ; Expected time at stop
  current-stop status tripcount heading-target  ; Current status
  pre-trip-time waiting-time walking-time ride-time  ; Time components
  min-travel-time tot-travel-time time-stretch  ; Travel time statistics
  ride-distance                       ; Distance traveled
]

; Past user breed and properties (for statistics)
breed [ past-users past-user ]
past-users-own [
  group-size request-time             ; Size of the user group and request time
  origin destination                  ; Origin and destination
  latest-pick-up-time latest-drop-off-time  ; Time constraints
  origin-stop destination-stop transfer-stop  ; Stops for the trip
  user-tripID-list                    ; List of trip IDs [line_ID, trip_num]
  stop-expected-time                  ; Expected time at stop
  current-stop status tripcount heading-target  ; Current status
  pre-trip-time waiting-time walking-time ride-time  ; Time components
  min-travel-time tot-travel-time time-stretch  ; Travel time statistics
  ride-distance                       ; Distance traveled
]

; Setup the transit service
to SETUP-SERVICE
  ; Initialize the simulation
  initial-setup

  ; Setup the origin-destination demand (commented out in original)
  ;Setup-OD-DEMAND

  ; Setup parameters, lines, and vehicles
  setup-parameters
  setup-lines
  setup-vehicles

  output-show "********** READY **********"
  reset-ticks
end

; Initialize the simulation environment
to initial-setup
  file-close-all
  stop-inspecting-dead-agents
  ask patches [set pcolor gray + 2]  ; Set background color
  set mouse-clicked false
  set flag-link false
  ; Set turtle shapes and appearances
  set-default-shape vehicles "bus"
  set-default-shape users "person"
  set-default-shape past-users "person"

  ; Initialize simulation parameters
  set start-sim-time 6 * 3600    ; 6:00 AM in seconds
  set end-sim-time 21 * 3600     ; 9:00 PM in seconds
  set max-walk-dist 400          ; Maximum walking distance in meters
  set tau-terminal 180           ; Time at terminal (seconds)
  set tau-stop 20                ; Time at stop (seconds)
  set tau-pax 2                  ; Time per passenger (seconds)
  set dt 60                      ; Simulation time step (seconds)
  set prob-1-pax 1               ; Probability of single passenger trip
  set ped-speed 1                ; Pedestrian speed (m/s = 3.6 km/h)
  set m/p 21.5                   ; Meters per patch (8620m = 400 patches)

  ; Weights for cost function
  set wgt-walk 2                 ; Weight for walking time
  set wgt-wait 2                 ; Weight for waiting time
  set wgt-ride 1                 ; Weight for riding time
  set wgt-oper 1                 ; Weight for operational cost

  set vehicle-capacity 50        ; Vehicle capacity
  set VoT 4                      ; Value of Time (€/h)
  set cost-km 1                  ; Cost per kilometer (€/km)
  set cost-h 20                  ; Cost per hour (€/h)
  set travel-time-threshold 3600 ; Maximum user tolerance (1 hour)
end

; Setup origin-destination demand data
to Setup-OD-DEMAND
  output-show "setup demand data ..."
  ; Demand coefficients for each hour of the day (24 values)
  set demand-coeff-list [ 0 0 0 0 0 0 0.076 0.080 0.067 0.076 0.095 0.079 0.079 0.068 0.081 0.079 0.072 0.065 0.054 0.016 0.013 0 0 0 ]
  set trip-OD-list n-values 24 [[]]  ; Initialize OD trips list for each hour

  ; Read trip data from file
  file-open "trips.txt"
  while [not file-at-end?] [
    let time-req file-read
    let oid file-read
    let did file-read
    let mylist item floor(time-req) trip-OD-list
    set mylist lput (list oid did) mylist
    set trip-OD-list replace-item floor(time-req) trip-OD-list mylist
    ; Highlight origin and destination zones on the map
    ask patches with [IDsez = oid or IDsez = did] [ set pcolor max list 10 (pcolor - 1) ]
  ]
  file-close
end

; Setup simulation parameters
to setup-parameters
  clear-output
  output-show "setup input parameters ..."
  clear-all-plots
  ask vehicles [die]
  ask users [die]
  ask past-users [die]

  ; Set random seed for reproducibility
  ifelse (rseed = 0) [random-seed new-seed] [random-seed rseed]

  ; Initialize time and counters
  set time start-sim-time
  set n-tot-users 0
  set n-of-accepted 0
  set n-of-delayed 0
  set n-of-rejected 0
  set n-of-transfers 0
  set n-tot-walking 0
  set time-avg-load-factor 0
  set time-avg-commercial-speed 0
  set total-travel-distance 0
  set total-energy-use 0
  set total-travel-time 0
  set tot-n-of-trips 0

  ; Reset streets and stop nodes
  ask streets [set color 26 set thickness 0 show-link]
  ask stop-nodes [
    set color grey
    set label-color black
    set label ""
    set occupancy 0
    set bookings 0
    set n-boarded 0
    set n-alighted 0
    set s-line-list []
    set is-drt-stop? true
  ]
end

; Setup transit lines
to setup-lines
  ; Initialize line names based on scenario
  output-show "importing TP lines ..."
  set line-name-list []
  (ifelse
    scenario = "FRT 1" [
      set line-name-list [ "01" "02" "03" "04" "05" "06H" "06F" ]
    ]
    scenario = "FRT 2" [
      set line-name-list [ "01" "02" "03" "04" "05" "06H" "06F" "P" "P2" "P3" "P5" ]
    ]
    scenario = "DRT 1" [
      set line-name-list [ "01" "02" "03" "04" "05" "06" ]
    ]
    scenario = "DRT 2" [
      set line-name-list [ "01" "02" "03" "04" "05" "06" "P" "P2" "P3" "P5" ]
    ]
  )
  ; Set service type based on scenario name
  set service-type substring scenario 0 3  ; "FRT" or "DRT"

  ; Initialize line-trip-list
  ; Multi-level hierarchical structure:
  ; Level 1: [line-trip-list] -> [line_0], [line_1] ... [line_l] ... [line_L]
  ; Level 2: -> [...[line_l]...] -> [trip_0], [trip_1] ... [trip_m] ... [trip_M]
  ; Level 3: -> [...[...[trip_m]...]...] -> S_0, S_1 ... S_n ... S_N, vehicleID
  ; Level 4: -> [...[...[...[S_n]...]...] -> [stop_n, tmin_n, tmax_n, X_n, n_onboard_n]
  set line-trip-list []
  let route-list [] ; List of routes, one per line

  ; Process each line
  let l 0
  repeat length line-name-list [
    let route-l []
    let oldtmin 0
    let tmin 0
    let tmax 0
    let lastfxstop 0
    let lastfxnode 0
    let laststop 0
    let lastnode 0
    let filename (word (item l line-name-list) ".txt")

    ; Read line data from file if it exists
    if file-exists? filename [
      output-show (word "opening file " filename " ... ")
      file-open filename
      let nil file-read-line ; Skip header row
      let ii 0

      ; Process each stop in the file
      while [not file-at-end?] [ ; Level 4 - setup the 5-tuple for each stop
        let mywho file-read
        let X_frt file-read
        let X_drt file-read
        let stp one-of stop-nodes with [who = mywho]

        ; Include stop based on service type (FRT or DRT)
        if (X_frt = 1 or service-type = "DRT") [
          let X ifelse-value (service-type = "FRT") [ X_frt ] [ X_drt ]

          ; Calculate time windows for this stop
          ifelse ii > 0 [
            let delta-tmin (time-between-stops lastfxstop stp lastfxnode)
            set tmin round (oldtmin + delta-tmin)
            if X = 1 [
              set lastfxnode item 1 (reverse (path-between-stops lastfxstop stp lastfxnode))
              set lastfxstop stp
              set oldtmin tmin
            ]
          ][
            set lastfxstop stp
          ]

          ifelse ii > 0 [
            let delta-tmax (time-between-stops laststop stp lastnode) + tau-stop
            set tmax round (tmax + delta-tmax)
            set lastnode item 1 (reverse (path-between-stops laststop stp lastnode))
            set laststop stp
          ][
            set laststop stp
          ]

          ; Add stop to route with time windows and status
          set route-l lput (list stp tmin tmax X 0) route-l

          ; Update stop node properties
          ask stp [
            if not member? l s-line-list [ set s-line-list lput l s-line-list ]
            if X = 1 [ set is-drt-stop? false ]
          ]
        ]
        set ii ii + 1
      ]
      file-close
    ]

    ; Add route to route list and initialize line's trips
    set route-list lput route-l route-list
    set line-trip-list lput [] line-trip-list
    set l l + 1
  ]

  ; Setup trip schedule based on routes
  setup-trip-schedule route-list
end

; Setup trip schedules for each line
to setup-trip-schedule [route-list]
  output-show "importing trip schedule ..."
  ; Choose appropriate schedule file based on scenario
  let schedule_filename 0
  (ifelse
    scenario = "FRT 1" [
      set schedule_filename "schedule_FRT1.txt"
    ]
    scenario = "FRT 2" [
      set schedule_filename "schedule_FRT2.txt"
    ]
    scenario = "DRT 1" [
      set schedule_filename "schedule_DRT1.txt"
    ]
    scenario = "DRT 2" [
      set schedule_filename "schedule_DRT2.txt"
    ]
  )

  ; Read schedule file
  file-open schedule_filename
  let nil file-read-line ; Skip header row
  while [not file-at-end?] [
    let l-name file-read
    let v-ID file-read
    let hhour file-read
    let mmin file-read
    let t0 (3600 * hhour + 60 * mmin)  ; Convert time to seconds
    let l position l-name line-name-list
    let line-l (item l line-trip-list)  ; Level 1
    let trip-m (item l route-list)      ; Level 2

    ; Update trip schedule with actual times
    let n 0
    repeat length trip-m [
      ; Update information for each stop in trip
      let tuple5-n (item n trip-m)      ; Level 3
      let tmin (item 1 tuple5-n) + t0   ; Add departure time to tmin
      let tmax (item 2 tuple5-n) + t0   ; Add departure time to tmax
      set tuple5-n replace-item 1 tuple5-n tmin
      set tuple5-n replace-item 2 tuple5-n tmax
      set trip-m replace-item n trip-m tuple5-n
      set n n + 1
    ]

    ; Add vehicle ID to trip and update line trips
    set trip-m lput v-ID trip-m         ; End Level 3
    set line-l lput trip-m line-l       ; End Level 2
    set line-trip-list replace-item l line-trip-list line-l  ; End Level 1
  ]
  file-close

  ; Add a fake last trip for the next day (to handle overnight services)
  let l 0
  repeat length line-trip-list [
    let line-l (item l line-trip-list)
    let trip-0 first line-l
    let n 0
    repeat (length trip-0 - 1) [
      let stop-n (item n trip-0)
      let tmin-n (item 1 stop-n)
      set stop-n replace-item 1 stop-n (tmin-n + 3600 * 24)  ; Add 24 hours
      let tmax-n (item 2 stop-n)
      set stop-n replace-item 2 stop-n (tmax-n + 3600 * 24)  ; Add 24 hours
      set trip-0 replace-item n trip-0 stop-n
      set n n + 1
    ]
    set line-l lput trip-0 line-l
    set line-trip-list replace-item l line-trip-list line-l
    set l l + 1
  ]

  ; Process the trips for each vehicle
  setup-trips
end

; Setup individual trips and assign to vehicles
to setup-trips
  output-show "setup trips ..."
  let l 0
  repeat length line-trip-list [ ; Level 1
    let line-l (item l line-trip-list)
    let m 0
    repeat length line-l [ ; Level 2
      let trip-m item m line-l
      ; Get vehicle ID and departure time
      let vID last trip-m
      let dpt-time item 1 (first trip-m)

      ; Assign trip to vehicle - create new or add to existing
      ifelse any? vehicles with [vehID = vID] [
        ; If vehicle already exists, add this trip to its schedule
        ask one-of vehicles with [vehID = vID] [
          let pos 0
          repeat length v-trip-list [
            if dpt-time > last (item pos v-trip-list) [ set pos pos + 1 ]
          ]
          set v-trip-list insert-item pos v-trip-list (list l m dpt-time)
        ]
      ][
        ; If vehicle doesn't exist, create a new one with this trip
        create-vehicles 1 [
          set vehID vID
          set v-trip-list (list (list l m dpt-time))
        ]
      ]
      set m m + 1
    ] ; End Level 2
    set l l + 1
  ] ; End Level 1

  ; Initialize passenger load profile for tracking
  setup-pax-load-profile
end

; Setup passenger load profile structure
to setup-pax-load-profile
  set pax-load-profile []
  let l 0
  ; Level 1 - for each line
  repeat length line-trip-list [
    let line-l (item l line-trip-list)
    let list-l n-values (length line-l) [[]]  ; Initialize with empty lists for each trip
    set pax-load-profile lput list-l pax-load-profile
    set l l + 1
  ]
end

; Setup vehicles and their properties
to setup-vehicles
  output-show "setup vehicles ..."

  ; Colors for different lines (maximum 15 lines)
  set color-list [ 15 55 95 35 75 115 135 25 5 45 85 105 125 65 0 ]
  let tthickness 0.8

  ; Initialize each vehicle
  ask vehicles [
    ; Initialize time tracking variables
    set stop-time 0
    set i-stop-time 0
    set tot-stop-time 0
    set count-stops 0
    set count-streets 0
    set n-of-trips 0

    ; Set status flags
    set move-flag false
    set terminal-flag true
    set stop-flag false
    set heading-flag false

    ; Initialize passenger and tracking lists
    set on-board-list []
    set travel-time-list []
    set travel-distance-list []

    ; Set line ID and name
    set lineID first (first v-trip-list)
    set linename (item lineID line-name-list)

    ; Get first trip and set terminal and stops
    let trip0 first (item lineID line-trip-list)
    set terminal first (first trip0)
    set stop-list (report-stoplist trip0 true false)
    set street-list (report-route stop-list)
    set last-stop terminal
    set next-stop first (item 1 stop-list)
    set current-street (first street-list)

    ; Set visual properties
    setxy ([xcor] of terminal) ([ycor] of terminal)
    set size 10
    set label-color black
    set heading 90
    set color (item lineID color-list)

    ; Draw the route on the map
    draw-route stop-list lineID 0.8
  ]

  ; Set energy consumption based on vehicle capacity
  set energy-consumption (ifelse-value
    vehicle-capacity < 6 [ 0.18 ]        ; Automobile 5 seats: 0.18 kWh/km
    vehicle-capacity >= 6 and vehicle-capacity < 9 [ 0.3 ]  ; Minivan 7-9 seats: 0.3 kWh/km
    vehicle-capacity >= 9 and vehicle-capacity < 22 [ 0.6 ] ; Minibus 15 seats: 0.6 kWh/km
    [ 1.0 ])  ; Bus with more than 21 passengers: 1 kWh/km

  ; Update street colors
  ask streets with [color = 25] [ set color 28 ]
end

; Main simulation loop
to GO
  ; Check if simulation should end
  if (time > end-sim-time) [
    if (count users = 0 or time > end-sim-time + 3600) [
      if export-results = "YES" [ export-outputs ]
      stop
    ]
  ]

  ; Update simulation time
  set time time + 1

  ; Update vehicles and users
  UPDATE-VEHICLE-STATUS
  UPDATE-USER-STATUS

  ; Generate new demand
  CREATE-DEMAND

  ; Update plots every minute of simulation time
  if (time / 60) = ceiling (time / 60) [ PLOT-UPDATING ]
end

; Update status of all vehicles
to UPDATE-VEHICLE-STATUS
  ; Handle vehicle idling (stopped at terminals/stops)
  vehicle-IDLING

  ; Handle vehicle movement on streets
  vehicle-MOVING

  ; Handle passenger pick-up and drop-off
  vehicle-PICKUP-DROPOFF
end

; Handle vehicles that are stopped/idling
to vehicle-IDLING
  ; Update vehicles that are not moving
  ask vehicles with [not move-flag] [
    set i-stop-time i-stop-time + 1

    ifelse terminal-flag [
      ; Vehicle is at terminal, check if it's time to depart
      let l first (item n-of-trips v-trip-list)
      let m item 1 (item n-of-trips v-trip-list)
      let dept last (item n-of-trips v-trip-list)

      if (length v-trip-list > n-of-trips and i-stop-time >= stop-time and time >= dept) [
        ; Update trip information before departure
        set tot-stop-time tot-stop-time + stop-time
        set i-stop-time 0
        set stop-time 0
        set terminal-flag false
        set count-stops 0
        set count-streets 0

        ; Update route information for new trip
        set lineID l
        set linename (item l line-name-list)
        let trip-m (item m (item l line-trip-list))
        set stop-list (report-stoplist trip-m true false)
        set street-list (report-route stop-list)
        set next-stop first (item 1 stop-list)
        set current-street (first street-list)
        let next-node [end2] of current-street
        set heading towards next-node
        set color (item l color-list)

        ; Update stop node appearances
        ask stop-nodes with [(bookings = 0 or occupancy = 0) and member? l s-line-list] [ set color grey ]

        ; Draw the route on the map
        draw-route stop-list l 0.8
      ]
    ][
      ; Vehicle is departing from a regular stop
      if (i-stop-time > stop-time) [
        set path-time path-time + stop-time
        set tot-stop-time tot-stop-time + stop-time
        set i-stop-time 0
        set stop-time 0
        set move-flag true
        set label ""
      ]
    ]
  ]
end

; Handle vehicle movement
to vehicle-MOVING
  ask vehicles with [move-flag = true and i-stop-time = 0] [
    ; Calculate movement radius based on speed
    let rrad (vehicle-speed / (3.6 * m/p))

    ; Move vehicle forward
    fd vehicle-speed / (3.6 * m/p)
    set path-time (path-time + 1)
    set travel-distance (travel-distance + vehicle-speed / 3.6)

    ; Update passenger ride distances
    foreach on-board-list [
      [pax] -> ask pax [ set ride-distance (ride-distance + vehicle-speed / 3.6) ]
    ]

    let next-node [end2] of current-street
    let currentstop 0
    let countstops 0

    ; Check if vehicle has reached a network node
    if (any? nodes in-radius rrad) [
      let hheading-flag heading-flag
      ask nodes in-radius rrad [
        if self = next-node [
          set hheading-flag true
        ]
      ]
      set heading-flag hheading-flag
    ]

    ; Check if vehicle has reached a stop
    ifelse (any? stop-nodes in-radius rrad) [
      let hheading-flag heading-flag
      let mmove-flag move-flag
      let sstop-flag stop-flag
      let tterminal-flag terminal-flag
      let nnext-stop next-stop
      let ppath-time path-time
      let tterminal terminal
      let stoplist stop-list
      set countstops count-stops + 1

      ask stop-nodes in-radius rrad [
        if self = next-node [ set hheading-flag true ]

        ; Check if this is the next scheduled stop
        if (self = nnext-stop) [
          set sstop-flag true
          set currentstop self

          ; If there are passengers to pick up/drop off, stop the vehicle
          if ((occupancy > 0 or bookings > 0) and self != tterminal) [
            set mmove-flag false
          ]

          ; Check if vehicle has returned to terminal
          if (self = tterminal and tterminal-flag = false and (countstops + 1) = length stoplist) [
            set mmove-flag false
            set currentstop tterminal
            set tterminal-flag true
            ask stop-nodes with [bookings = 0 or occupancy = 0] [ set color 5 ]
          ]
        ]
      ]

      ; Update flags
      set stop-flag sstop-flag
      set move-flag mmove-flag
      set heading-flag hheading-flag
      set terminal-flag tterminal-flag
    ][
      set last-stop terminal
    ]

    ; If vehicle has reached a stop, update information
    if stop-flag [
      set count-stops countstops
      set last-stop currentstop

      ; Update next stop if not at terminal
      if not terminal-flag [ set next-stop first (item (count-stops + 1) stop-list) ]

      ; Update the time information for the current trip
      let skip-flag ifelse-value move-flag [ true ] [ false ]
      let tripID (bl (item n-of-trips v-trip-list))
      UPDATE-stop-time self tripID skip-flag
      set stop-flag false
    ]

    ; If vehicle has reached a new street segment
    if heading-flag [
      if not terminal-flag [
        set count-streets count-streets + 1
        carefully [ set current-street (item count-streets street-list) ] [ ]
        set heading towards [end2] of current-street
      ]
      set heading-flag false
    ]
  ]
end

; Update stop times based on current vehicle position
to UPDATE-stop-time [thisvehicle tripID skip-flag]
  ; Get trip information
  let l first tripID
  let m last tripID
  let line-l (item l line-trip-list)
  let trip-m (item m line-l)
  let stoplist (report-stoplist trip-m false true)  ; false: don't include stop-time - true: include DRT stops
  let n (position last-stop bf stoplist + 1)
  let delta-tmin (time - (item 1 (item n trip-m)))
  let delta-tmax (time - (item 2 (item n trip-m)))

  ; Update time windows for all remaining stops in the trip
  repeat (length stoplist - n) [
    let stop-tuple (item n trip-m)
    let new-tmin (item 1 stop-tuple) + delta-tmin
    let new-tmax (item 2 stop-tuple) + delta-tmax
    set stop-tuple replace-item 1 stop-tuple new-tmin
    set stop-tuple replace-item 2 stop-tuple new-tmax
    set trip-m replace-item n trip-m stop-tuple
    set n n + 1
  ]

  ; Update trip in global list
  set line-l replace-item m line-l trip-m
  set line-trip-list replace-item l line-trip-list line-l

  ; Update current trip information for this vehicle
  ask thisvehicle [
    set stop-list (report-stoplist trip-m true false)  ; true: report stop times - false: exclude DRT stops
    set street-list (report-route stop-list)
  ]

  ; Update information for users
  let stoptimelist (report-stoplist trip-m true true)
  let terminal-time last (last stoptimelist)
  ask users with [status = "assigned" or status = "waiting"] [
    if (member? tripID user-tripID-list) and (stop-expected-time < terminal-time) [
      let j 1
      while [j < length stoptimelist] [
        if member? (first (item j stoptimelist)) (list origin-stop current-stop) [
          set stop-expected-time last (item j stoptimelist)
        ]
        set j j + 1
      ]
    ]
  ]
end

; Handle passenger pickup and dropoff
to vehicle-PICKUP-DROPOFF
  ask vehicles with [move-flag = false and i-stop-time = 0] [
    ; Track current stop and trip information
    let currentstop last-stop
    let n-do-users 0
    let tripID bl (item n-of-trips v-trip-list)  ; 2-tuple [line_ID, trip_ID]

    ; DROPOFF PROCEDURE
    if (length on-board-list > 0) [
      let onboardlist on-board-list
      let ii 0

      repeat length on-board-list [
        ask item ii on-board-list [
          ; Drop off passengers who reached their destination
          if (destination-stop = currentstop) [
            set onboardlist remove self onboardlist
            set xcor [xcor] of destination-stop
            set ycor [ycor] of destination-stop
            fd random-float 0.1
            set color grey
            set status "walking"
            show-turtle
            set heading towards destination

            ; Update delay statistics
            if (time > latest-drop-off-time) [ set n-of-delayed n-of-delayed + group-size ]
            set n-do-users (n-do-users + group-size)
          ]

          ; Handle transfers to other lines
          if (transfer-stop = currentstop) [
            if tripcount < length user-tripID-list [  ; tripcount = 1
              set onboardlist remove self onboardlist
              set xcor [xcor] of transfer-stop
              set ycor [ycor] of transfer-stop
              set color blue
              set status "waiting"
              show-turtle
              set current-stop transfer-stop
              set n-of-transfers n-of-transfers + group-size
              let transfer-group-size group-size
              set n-do-users (n-do-users + group-size)
              ask transfer-stop [ set occupancy (occupancy + transfer-group-size) ]
            ]
          ]
        ]
        set ii ii + 1
      ]

      ; Update vehicle and stop information after dropoffs
      set on-board-list onboardlist
      set label length on-board-list
      ask currentstop [
        set bookings (bookings - n-do-users)
        set n-alighted (n-alighted + n-do-users)
      ]
    ]

    ; Update stop time if passengers were dropped off
    if (n-do-users > 0) [
      if not terminal-flag [
        if stop-time = 0 [ set stop-time tau-stop ]
        set stop-time stop-time + (tau-pax * n-do-users)
      ]
    ]

    ; PICKUP PROCEDURE
    let n-pu-users 0
    if ([occupancy] of currentstop > 0) [
      ; Find users waiting at this stop whose next trip matches this vehicle
      let compatible-groups users with [status = "waiting" and current-stop = currentstop and tripID = item tripcount user-tripID-list]

      if (count compatible-groups > 0) [
        let compatible-groups-list sort-on [request-time] compatible-groups

        repeat length compatible-groups-list [
          let selected-group last compatible-groups-list
          let groupsize 0

          ask selected-group [
            hide-turtle
            setxy 0 0
            set status "on-board"
            set current-stop nobody
            set tripcount tripcount + 1
            set n-pu-users (n-pu-users + group-size)
          ]

          ; Add group to vehicle's passenger list
          set on-board-list lput selected-group on-board-list
          set compatible-groups-list remove selected-group compatible-groups-list
        ]

        ; Update stop statistics after pickups
        ask currentstop [
          set occupancy (occupancy - n-pu-users)
          set n-boarded (n-boarded + n-pu-users)
        ]
      ]

      ; Update stop time for pickup operations
      if (n-pu-users > 0) [
        if not terminal-flag [
          if stop-time = 0 [ set stop-time tau-stop ]
          set stop-time stop-time + (tau-pax * n-pu-users)
        ]
      ]
    ]

    ; Update passenger load profile if there was any activity
    if (n-pu-users + n-do-users > 0) [
      let l (first tripID)
      let m (last tripID)
      let list-l item l pax-load-profile
      let list-m lput (list currentstop n-pu-users n-do-users) (item m (item l pax-load-profile))
      set list-l replace-item m list-l list-m
      set pax-load-profile replace-item l pax-load-profile list-l
      set label length on-board-list
    ]

    ; Handle trip completion when vehicle returns to terminal
    if terminal-flag and count-stops > 0 [
      ; Update global statistics
      set total-travel-distance precision (total-travel-distance + travel-distance) 0
      set total-travel-time precision (total-travel-time + path-time) 0
      set total-energy-use total-energy-use + (travel-distance / 1000) * energy-consumption

      ; Save trip statistics
      set travel-time-list lput path-time travel-time-list
      set travel-distance-list lput (precision travel-distance 0) travel-distance-list
      set commercial-speed (3.6 * travel-distance / path-time)

      ; Reset counter for next trip
      set count-stops -1
      set count-streets -1
      set path-time 0
      set travel-distance 0
      set tot-n-of-trips (tot-n-of-trips + 1)
      set stop-time tau-terminal
      set n-of-trips (n-of-trips + 1)
    ]
  ]
end

; Update all users status
to UPDATE-USER-STATUS
  ; Update users who have been assigned but haven't started walking yet
  ask users with [status = "assigned"] [
    set pre-trip-time pre-trip-time + 1
    let walk-time-O ceiling ((compute-distance self origin-stop) * m/p / ped-speed)

    ; Start walking if it's time to reach the stop
    if (stop-expected-time - time <= walk-time-O + dt) [
      set status "walking"
      set waiting-time pre-trip-time  ; Assumption: pre-trip time counts as waiting time
      set pre-trip-time 0
    ]
  ]

  ; Update users who are walking
  ask users with [status = "walking"] [
    ; Move user
    let one-step (ped-speed / m/p)
    fd one-step
    set walking-time (walking-time + 1)
    let groupsize group-size

    ; Check if user reached a stop
    if (any? stop-nodes in-radius one-step) [
      if ((one-of stop-nodes in-radius one-step) = origin-stop and origin-stop != destination-stop) [
        set color blue
        set status "waiting"
        ask origin-stop [ set occupancy (occupancy + groupsize) ]
        set current-stop origin-stop
      ]

      if (one-of stop-nodes in-radius one-step) = destination-stop [
        set status "walking"  ; Continue walking on last leg
      ]
    ]

    ; Check if user reached final destination
    if (one-of patches in-radius one-step) = destination [
      set status "arrived"
    ]
  ]

  ; Update users who are waiting at a stop
  ask users with [status = "waiting"] [
    set waiting-time waiting-time + 1
    ; Change color if waiting too long
    if (waiting-time > max-waiting-time) [ set color pink ]
  ]

  ; Update users who are on board a vehicle
  ask users with [status = "on-board"] [
    let tripID (item (tripcount - 1) user-tripID-list)
    let myvehicle one-of vehicles with [tripID = bl (item n-of-trips v-trip-list)]

    ; If vehicle is at terminal, count as waiting time, otherwise as ride time
    ifelse [terminal-flag] of myvehicle [
      set waiting-time waiting-time + 1
    ][
      set ride-time (ride-time + 1)
    ]
  ]

  ; Process users who have reached their destination
  ask users with [status = "arrived"] [
    ; Calculate final statistics
    set tot-travel-time (waiting-time + walking-time + ride-time)
    set min-travel-time (min-travel-time + walking-time)
    set time-stretch (tot-travel-time / min-travel-time)

    ; Convert to past-user for statistics
    set breed past-users
    hide-turtle

    ; Create copies for multiple passengers in group
    if group-size > 1 [ hatch (group-size - 1) ]
  ]
end

; Generate new travel demand
to CREATE-DEMAND
  let rrate 0
  let t-hr (time / 3600)
  let temp-cum-demand (demand-rate * sum (sublist demand-coeff-list 0 (ceiling t-hr)))  ; Total passengers

  ; Calculate current demand rate
  if time < end-sim-time [
    carefully [ set rrate (temp-cum-demand - n-tot-users) / (3600 * (ceiling t-hr) - time) ] []
  ]

  ; Randomly create new users based on demand rate
  if (random-float 1 < rrate) [
    let new-user nobody

    ; Select a random OD pair for this hour
    let mytriplist item (floor t-hr) trip-OD-list
    let myOD one-of mytriplist
    let oorigin (one-of patches with [IDsez = first myOD])
    let ddestination (one-of patches with [IDsez = last myOD])

    ; Handle edge cases
    if oorigin = nobody [ show myOD ]
    if ddestination = nobody [ show myOD ]
    if ddestination = oorigin [ ask oorigin [ set ddestination one-of neighbors ] ]

    ; Create the new user
    ask oorigin [
      sprout-users 1 [
        show-turtle
        jump random-float 0.1
        set size 3
        set color black
        set label ""

        ; Determine group size using geometric distribution
        let p_n random-float 1
        let p_1 prob-1-pax  ; 90%
        let p_2 prob-1-pax * (1 - prob-1-pax)  ; 9%
        let p_3 prob-1-pax * (1 - prob-1-pax)^ 2  ; 0.9%
        let p_4 (1 - p_1 - p_2 - p_3)  ; 0.1%

        set group-size (ifelse-value
          p_n < p_1  [ 1 ]
          p_n >= p_1 and p_n < p_1 + p_2 [ 2 ]
          p_n >= p_1 + p_2 and p_n < p_1 + p_2 + p_3 [ 3 ]
          [ 4 ])

        ; Initialize user properties
        set origin oorigin
        set destination ddestination
        set user-tripID-list []
        set current-stop nobody
        set tripcount 0
        set origin-stop 0
        set destination-stop 0
        set transfer-stop 0
        set pre-trip-time 0
        set waiting-time 0
        set new-user self

        ; Update global user counter
        set n-tot-users n-tot-users + group-size
      ]
    ]

    ; Match the new user to transit services
    user-MATCHING new-user
  ]
end

; Match a user to the best transit option
to user-MATCHING [new-user]
  set solution-list []

  ask new-user [
    let walk-radius (max-walk-dist / m/p)
    let oorigin origin
    let ddestination destination
    let groupsize group-size
    let traveltime-min travel-time-threshold

    ; Check if walking the whole way is feasible
    ifelse compute-distance origin destination > walk-radius [
      set reject-flag false

      ; Find nearby stops for origin and destination
      let origin-stops-list sort-on [distance oorigin] stop-nodes with [distance oorigin <= walk-radius]
      let destination-stops-list sort-on [distance ddestination] stop-nodes with [distance ddestination <= walk-radius]

      ; Filter origin stops to reduce combinations (one stop per line)
      let filtered-origin-stops-list []
      let o-line-list []
      let i 0
      repeat length origin-stops-list [
        ask (item i origin-stops-list) [
          let stop-i self
          foreach s-line-list [
            [l] -> if not member? l o-line-list [
              set filtered-origin-stops-list remove-duplicates (lput stop-i filtered-origin-stops-list)
              set o-line-list lput l o-line-list
            ]
          ]
        ]
        set i i + 1
      ]

      ; Filter destination stops similarly
      let filtered-destination-stops-list []
      let d-line-list []
      let j 0
      repeat length destination-stops-list [
        ask (item j destination-stops-list) [
          let stop-j self
          foreach s-line-list [
            [l] -> if not member? l d-line-list [
              set filtered-destination-stops-list remove-duplicates (lput stop-j filtered-destination-stops-list)
              set d-line-list lput l d-line-list
            ]
          ]
        ]
        set j j + 1
      ]

      ; Set request time with advance booking for DRT
      let delta-request-time 0
      foreach filtered-origin-stops-list [
        [os] -> if ([is-drt-stop?] of os) and (delta-request-time = 0) [ set delta-request-time 0 ]
      ]
      set request-time (time + delta-request-time)

      ; Calculate minimum travel time (direct route)
      ask min-one-of nodes [distance oorigin] [
        let this-destination-stop min-one-of nodes [distance ddestination]
        set traveltime-min precision ((nw:weighted-distance-to this-destination-stop street-length) / (vehicle-speed / 3.6)) 0
      ]

      ; Set user time constraints
      let gamma 1 + precision (random-float 2) 1  ; Random number between 1 and 3
      let delta 1 + precision (random-float 1) 1  ; Random number between 1 and 2
      set latest-pick-up-time request-time + gamma * max-waiting-time  ; User can wait 20-60 min
      set latest-drop-off-time precision (latest-pick-up-time + delta * traveltime-min) 0

      ; Run matching algorithm to find best transit option
      matching-algorithm new-user oorigin ddestination filtered-origin-stops-list filtered-destination-stops-list traveltime-min groupsize request-time

      ; If no solution found, mark as rejected
      if empty? solution-list [ set reject-flag true ]

      ; Assign user status based on matching results
      ifelse reject-flag [
        ; Handle rejected request
        set status "rejected"
        set color red
        set n-of-rejected n-of-rejected + group-size
        set breed past-users
        set shape "x"
      ][
        let trip-updated-list []

        ; Choose best solution (minimum cost)
        let cost-list map [sl -> (first sl)] solution-list
        let best-cost min cost-list
        let bestsolpos position best-cost cost-list
        let best-solution item bestsolpos solution-list

        ; Process the best solution
        let n-trips length (bf best-solution)
        let ii 0
        repeat n-trips [
          let sol-list item ii (bf best-solution)
          let tripID first sol-list  ; [line_ID, trip_num]
          let pos-in-trip last sol-list  ; [n1 n2]
          let n1 first pos-in-trip
          let n2 last pos-in-trip
          let trip-updated (report-updated-trip tripID pos-in-trip group-size)

          ; Set origin, transfer, and destination stops
          if ii = 0 [
            set origin-stop first (item n1 trip-updated)  ; Origin stop is pickup stop in first trip
            if n-trips > 1 [
              set transfer-stop first (item n2 trip-updated)  ; Transfer stop when multiple trips needed
            ]
          ]
          if ii = (n-trips - 1) [
            set destination-stop first (item n2 trip-updated)  ; Destination stop is dropoff in last trip
          ]

          ; Build list of updated trips
          set trip-updated-list lput (list tripID trip-updated) trip-updated-list
          set ii ii + 1
        ]

        ; If origin and destination are different stops, process transit journey
        ifelse origin-stop != destination-stop [
          let jj 0
          repeat n-trips [
            let trip-updated-pair item jj trip-updated-list
            let tripID (first trip-updated-pair)
            let trip-updated (last trip-updated-pair)
            let l first tripID
            let m last tripID

            ; Update the line schedule
            let line-updated (item l line-trip-list)
            set line-updated replace-item m line-updated trip-updated
            set line-trip-list replace-item l line-trip-list line-updated

            ; Update vehicle stop list if trip is ongoing
            ask vehicles [
              if tripID = bl (item n-of-trips v-trip-list) [
                set stop-list (report-stoplist trip-updated true false)
                set street-list (report-route stop-list)
              ]
            ]

            ; Add trip to user's itinerary
            set user-tripID-list lput tripID user-tripID-list
            set jj jj + 1
          ]

          ; Update user attributes and statistics
          set min-travel-time traveltime-min
          ask origin-stop [ set color blue ]
          ask destination-stop [ set bookings bookings + 1 set color blue set label-color black set label bookings ]
          if transfer-stop != 0 [ ask transfer-stop [ set bookings bookings + 1 set label-color black set label bookings ] ]

          set n-of-accepted n-of-accepted + group-size
          set color black
          set status "assigned"
          set heading towards origin-stop
        ][
          ; If origin and destination are the same stop, walk directly
          set min-travel-time traveltime-min
          set n-tot-walking n-tot-walking + group-size
          set color grey
          set status "walking"
          set heading towards destination
        ]
      ]
    ][
      ; Destination is close enough to walk directly
      set min-travel-time traveltime-min
      set n-tot-walking n-tot-walking + group-size
      set color grey
      set status "walking"
      set heading towards destination
    ]
  ]
end

; Complex matching algorithm to find best transit options
to matching-algorithm [new-user oorigin ddestination origin-stops-list destination-stops-list traveltime-min groupsize rrequest-time]
  let latest-arrival-time (rrequest-time + 3600)  ; Maximum 1 hour trip

  ; Level 1 - Search for possible origin stops
  let i 0
  repeat length origin-stops-list [
    let pickup-stop (item i origin-stops-list)

    ; Calculate walking time to origin stop
    let walk-time-O ceiling ((m/p * compute-distance oorigin pickup-stop) / ped-speed + 10)

    ; Level 2 - Search for possible destination stops
    let j 0
    repeat length destination-stops-list [
      let dropoff-stop (item j destination-stops-list)

      if dropoff-stop != pickup-stop [
        let walk-time-D ceiling ((m/p * compute-distance ddestination dropoff-stop) / ped-speed + 10)

        ; Level 3 - Search for possible lines serving origin stop
        let m 0
        repeat length line-trip-list [
          if member? m ([s-line-list] of pickup-stop) [

            ; Level 4 - Search for possible lines serving destination stop
            let n 0
            repeat length line-trip-list [
              if member? n ([s-line-list] of dropoff-stop) [

                ; Check if same line can serve both stops (direct trip)
                ifelse (m = n) [
                  ; Find the first trip that can serve this request
                  let triplist1 (item m line-trip-list)
                  let start-trip-flag true
                  let trn1 0
                  while [start-trip-flag] [
                    let thistrip bl (item trn1 triplist1)
                    ifelse rrequest-time < item 1 (last thistrip) [ set start-trip-flag false ] [ set trn1 trn1 + 1 ]
                  ]

                  ; Search for possible direct trip solutions
                  let next-trip-flag1 true
                  while [ next-trip-flag1 ] [
                    let feasibility-flag true
                    let input-param-cost-function []
                    let thistrip1 bl (item trn1 triplist1)
                    let thisstoplist (report-stoplist thistrip1 false true)
                    let pos-O (position pickup-stop thisstoplist)
                    let user-arrival-time-O rrequest-time + walk-time-O

                    ; Check time-window constraints at origin
                    ifelse item 2 (item pos-O thistrip1) < latest-arrival-time [
                      if (item 1 (item pos-O thistrip1) > user-arrival-time-O) [
                        ; Check destination position
                        let pos-D (position dropoff-stop (bf thisstoplist) + 1)
                        let pos1.1 pos-O
                        let pos1.2 0
                        let trip-updated1 []

                        ifelse pos-D > pos-O [
                          ; Destination is after origin in same trip
                          set pos1.2 pos-D
                          set trip-updated1 (report-updated-trip (list m trn1) (list pos1.1 pos1.2) groupsize)
                        ][
                          ; Destination requires next trip
                          set pos1.2 (length thisstoplist - 1)
                          set trip-updated1 (report-updated-trip (list m trn1) (list pos1.1 pos1.2) groupsize)
                        ]

                        ; Check time constraints at destination
                        if item 2 (item pos1.2 trip-updated1) < latest-arrival-time [
                          ; Check capacity constraints
                          let p1 pos1.1
                          while [feasibility-flag and p1 <= pos1.2] [
                            let tuple (item p1 trip-updated1)
                            if item 4 tuple > vehicle-capacity [ set feasibility-flag false ]
                            set p1 p1 + 1
                          ]

                          if feasibility-flag [
                            set input-param-cost-function lput (list thistrip1 trip-updated1 pos1.1 pos1.2) input-param-cost-function
                            let solution-trip1 (list (list m trn1) (list pos1.1 pos1.2))

                            ; Check if destination is reached in this trip
                            ifelse pos1.2 = pos-D [
                              ; Direct trip solution
                              let cost (COST-FUNCTION rrequest-time walk-time-O walk-time-D traveltime-min groupsize input-param-cost-function)
                              set solution-list lput (list cost solution-trip1) solution-list
                            ][
                              ; Need second trip
                              let trn2 trn1 + 1
                              let thistrip2 bl (item trn2 triplist1)

                              if (item 2 (item pos-D thistrip2) < latest-arrival-time) [
                                let pos2.1 0
                                let pos2.2 pos-D
                                let trip-updated2 (report-updated-trip (list m trn2) (list pos2.1 pos2.2) groupsize)

                                ; Check capacity on second trip
                                let p2 0
                                while [feasibility-flag and p2 < pos2.2] [
                                  let tuple (item p2 trip-updated2)
                                  if item 4 tuple > vehicle-capacity [ set feasibility-flag false ]
                                  set p2 p2 + 1
                                ]

                                if feasibility-flag [
                                  set input-param-cost-function lput (list thistrip1 trip-updated1 pos1.1 pos1.2) input-param-cost-function
                                  let solution-trip2 (list (list n trn2) (list pos2.1 pos2.2))

                                  ; Two-trip direct line solution
                                  let cost (COST-FUNCTION rrequest-time walk-time-O walk-time-D traveltime-min groupsize input-param-cost-function)
                                  set solution-list lput (list cost solution-trip1 solution-trip2) solution-list
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                      set trn1 trn1 + 1
                    ][
                      set next-trip-flag1 false
                    ]

                    ; Safety check to prevent infinite loops
                    if trn1 >= length triplist1 [ set next-trip-flag1 false ]
                  ]
                ][
                  ; Different lines needed (transfer required)
                  if empty? solution-list [
                    ; Level 5 - Search for possible transfer stops
                    let transfer-stops-list (sort stop-nodes with [member? m s-line-list and member? n s-line-list])
                    let k 0
                    repeat length transfer-stops-list [
                      let pudo-stop (item k transfer-stops-list)

                      if pudo-stop != dropoff-stop and pudo-stop != pickup-stop [
                        ; Find first eligible trip on first line
                        let triplist1 (item m line-trip-list)
                        let start-trip-flag1 true
                        let trn1start 0
                        while [start-trip-flag1] [
                          let thistrip bl (item trn1start triplist1)
                          ifelse rrequest-time < item 1 (last thistrip) [ set start-trip-flag1 false ] [ set trn1start trn1start + 1 ]
                        ]

                        ; Find first eligible trip on second line
                        let triplist2 (item n line-trip-list)
                        let start-trip-flag2 true
                        let trn2start 0
                        while [start-trip-flag2] [
                          let thistrip bl (item trn2start triplist2)
                          ifelse rrequest-time < item 1 (last thistrip) [ set start-trip-flag2 false ] [ set trn2start trn2start + 1 ]
                        ]

                        ; Search for origin-transfer-destination solutions
                        let trn1 trn1start
                        let next-trip-flag1 true
                        while [ next-trip-flag1 ] [
                          let feasibility-flag true
                          let input-param-cost-function []
                          let thistrip1 bl (item trn1 triplist1)
                          let thisstoplist1 (report-stoplist thistrip1 false true)
                          let pos1.1 (position pickup-stop thisstoplist1)
                          let pos1.2 (position pudo-stop (bf thisstoplist1) + 1)

                          ; Check if transfer stop is after origin stop
                          if pos1.2 > pos1.1 [
                            let user-arrival-time-O rrequest-time + walk-time-O

                            ; Check time constraints at origin
                            ifelse item 2 (item pos1.1 thistrip1) < latest-arrival-time [
                              if (item 1 (item pos1.1 thistrip1) > user-arrival-time-O) [
                                let trip-updated1 (report-updated-trip (list m trn1) (list pos1.1 pos1.2) groupsize)

                                ; Check time window constraints at transfer point
                                if item 2 (item pos1.2 trip-updated1) < latest-arrival-time [
                                  ; Check capacity constraints for first trip
                                  let p1 pos1.1
                                  while [feasibility-flag and p1 <= pos1.2] [
                                    let tuple (item p1 trip-updated1)
                                    if item 4 tuple > vehicle-capacity [ set feasibility-flag false ]
                                    set p1 p1 + 1
                                  ]

                                  if feasibility-flag [
                                    set input-param-cost-function lput (list thistrip1 trip-updated1 pos1.1 pos1.2) input-param-cost-function
                                    let solution-trip1 (list (list m trn1) (list pos1.1 pos1.2))

                                    ; Search for second trip (after transfer)
                                    let trn2 trn2start
                                    let next-trip-flag2 true
                                    while [ next-trip-flag2 ] [
                                      let thistrip2 bl (item trn2 triplist2)
                                      let thisstoplist2 (report-stoplist thistrip2 false true)
                                      let pos2.1 (position pudo-stop thisstoplist2)
                                      let pos2.2 (position dropoff-stop (bf thisstoplist2) + 1)

                                      if pos2.2 > pos2.1 [
                                        let user-arrival-time-D (item 2 (item pos2.2 thistrip2))

                                        ; Check time constraints at destination
                                        ifelse user-arrival-time-D < latest-arrival-time [
                                          let trip-updated2 (report-updated-trip (list n trn2) (list pos2.1 pos2.2) groupsize)

                                          ; Check if transfer is feasible (first trip arrives before second departs)
                                          if item 2 (item pos1.2 trip-updated1) < item 1 (item pos2.1 trip-updated2) [
                                            ; Check capacity constraints for second trip
                                            let p2 0
                                            while [feasibility-flag and p2 < pos2.2] [
                                              let tuple (item p2 trip-updated2)
                                              if item 4 tuple > vehicle-capacity [ set feasibility-flag false ]
                                              set p2 p2 + 1
                                            ]

                                            if feasibility-flag [
                                              set input-param-cost-function lput (list thistrip2 trip-updated2 pos2.1 pos2.2) input-param-cost-function
                                              let solution-trip2 (list (list n trn2) (list pos2.1 pos2.2))

                                              ; Add two-trip transfer solution to solution list
                                              let cost (COST-FUNCTION rrequest-time walk-time-O walk-time-D traveltime-min groupsize input-param-cost-function)
                                              set solution-list lput (list cost solution-trip1 solution-trip2) solution-list
                                            ]
                                          ]
                                        ][
                                          set next-trip-flag1 false
                                        ]
                                      ]
                                      set trn2 trn2 + 1

                                      ; Safety check to prevent infinite loops
                                      if trn2 >= length triplist2 [ set next-trip-flag2 false ]
                                    ]
                                  ]
                                ]
                              ]
                            ][
                              set next-trip-flag1 false
                            ]
                          ]
                          set trn1 trn1 + 1

                          ; Safety check to prevent infinite loops
                          if trn1 >= length triplist1 [ set next-trip-flag1 false ]
                        ]
                      ]
                      set k k + 1
                    ]
                  ]
                  ; End level 5
                ]
              ]
              set n n + 1
              ; End level 4 - loop lines trip 2
            ]
          ]
          set m m + 1
          ; End level 3 - loop lines trip 1
        ]
      ]
      set j j + 1
      ; End level 2 - loop destination-stops-list
    ]
    set i i + 1
    ; End level 1 - loop origin-stops-list
  ]
end

; Calculate cost function for evaluating transit options
to-report COST-FUNCTION [ requestime walk-time-O walk-time-D traveltime-min groupsize input-list ]
  ; Initialize user and operator costs
  let operator-cost 0
  let user-cost (wgt-walk * (walk-time-O + walk-time-D) - wgt-ride * traveltime-min)

  ; Start with request time plus walking to origin stop
  let travel-time-progr (requestime + walk-time-O)

  let i 0
  repeat length input-list [
    let trip-input-i (item i input-list)  ; The i-th trip leg of the total OD trip

    ; Get trip information
    let trip-current item 0 trip-input-i
    let trip-updated item 1 trip-input-i
    let pos1 item 2 trip-input-i
    let pos2 item 3 trip-input-i

    ; Calculate additional time due to modifications
    let tmin2old item 1 (item pos2 trip-current)
    let tmin2 item 1 (item pos2 trip-updated)
    let delta-time (tmin2 - tmin2old)

    ; Calculate expected waiting time at pickup-stop
    let tmin1 item 1 (item pos1 trip-updated)
    let waitingtime (tmin1 - travel-time-progr)

    ; Calculate expected ride time for this leg
    let ridetime (tmin2 - tmin1)
    set travel-time-progr tmin2

    ; Add transfer penalty (5 minutes) for additional trips
    let transfer-penalty 300

    ; Update costs
    set user-cost user-cost + (wgt-wait * waitingtime + wgt-ride * ridetime + transfer-penalty)
    set operator-cost operator-cost + (wgt-oper * delta-time)
    set i i + 1
  ]

  ; Convert to monetary values
  set user-cost (user-cost * groupsize * (VoT / 3600))  ; Value of time in €/sec per passenger
  set operator-cost (operator-cost * (cost-km * vehicle-speed / 3600))  ; Operating cost per second

  ; Total cost combines user and operator perspectives
  let cost (user-cost + operator-cost)
  report precision cost 3
end

; Create an updated trip with new passenger load
to-report report-updated-trip [tripID n1-n2 groupsize]
  ; Get trip information
  let l first tripID
  let m last tripID
  let trip-m bl (item m (item l line-trip-list))
  let n1 first n1-n2
  let n2 last n1-n2

  ; Initialize variables for path calculation
  let lastfxstop first (first trip-m)
  let lastfxnode lastfxstop
  let laststop lastfxstop
  let lastnode lastfxnode
  let tmin item 1 (first trip-m)
  let oldtmin tmin
  let tmax item 2 (first trip-m)
  let X item 3 (first trip-m)

  ; Process stops before pickup point (n1) to establish reference points
  let n 0
  while [n < n1] [
    let stp first (item n trip-m)
    set X item 3 (item n trip-m)

    ; Update reference points for fixed stops
    if X = 1 [
      let path (path-between-stops lastfxstop stp lastfxnode)
      if length path > 1 [ set lastfxnode item 1 (reverse path) ]
      set lastfxstop stp
    ]

    ; Update reference points for all stops
    let pathfx (path-between-stops laststop stp lastnode)
    if length pathfx > 1 [ set lastnode item 1 (reverse pathfx) ]
    set laststop stp
    set n n + 1
  ]

  ; Get times at pickup point (n1)
  set tmin item 1 (item n trip-m)
  set tmax item 2 (item n trip-m)
  set oldtmin tmin

  ; Update all stops from pickup (n1) onwards
  while [n < length trip-m] [
    let stp first (item n trip-m)
    set X item 3 (item n trip-m)
    let load item 4 (item n trip-m)

    ; Update minimum time when we're past pickup point
    if n > n1 [ set tmin oldtmin + round (time-between-stops lastfxstop stp lastfxnode) ]

    ; Update reference points for fixed stops
    if X = 1 [
      let path (path-between-stops lastfxstop stp lastfxnode)
      if length path > 1 [ set lastfxnode item 1 (reverse path) ]
      set lastfxstop stp
      set oldtmin tmin
    ]

    ; Update maximum time for all stops after pickup
    if n > n1 [ set tmax tmax + round (time-between-stops laststop stp lastnode) + tau-stop ]

    ; Update reference points for all stops
    let pathfx (path-between-stops laststop stp lastnode)
    if length pathfx > 1 [ set lastnode item 1 (reverse pathfx) ]
    set laststop stp

    ; Activate stops that are pickup or dropoff points
    if (n = n1 or n = n2) [ set X 1 ]

    ; Update passenger load between pickup and dropoff
    if (n >= n1 and n < n2) [ set load (load + groupsize) ]

    ; Replace the stop's tuple with updated information
    set trip-m replace-item n trip-m (list stp tmin tmax X load)
    set n n + 1
  ]

  ; Add vehicle ID back to the trip
  set trip-m lput (last (item m (item l line-trip-list))) trip-m
  report trip-m
end

; Update plots during simulation
to PLOT-UPDATING
  let n-vehicles count vehicles

  ; Plot user experience metrics
  set-current-plot "user-experience"
  set-current-plot-pen "A"
  plotxy (time / 60) n-of-accepted
  set-current-plot-pen "R"
  plotxy (time / 60) n-of-rejected
  set-current-plot-pen "D"
  plotxy (time / 60) n-of-delayed

  ; Plot vehicle occupancy
  set-current-plot "average-vehicle-occupancy"
  set-current-plot-pen "default"
  set-plot-y-range 0 (vehicle-capacity + 1)
  let tot-users-onboard sum [length on-board-list] of vehicles
  let avg-veh-occupancy (tot-users-onboard / n-vehicles)
  plotxy (time / 60) avg-veh-occupancy

  ; Create load histogram
  set-current-plot "average-load-histogram"
  clear-plot
  set-plot-x-range 1 (n-vehicles + 1)
  set-plot-y-range 0 vehicle-capacity
  set-current-plot-pen "max-cap"
  plotxy 0 vehicle-capacity
  plotxy (n-vehicles + 1) vehicle-capacity
  set-current-plot-pen "default"
  ask vehicles [plotxy vehID length on-board-list]

  ; Create boarding histogram
  set-current-plot "n-boarded-histogram"
  clear-plot
  set-plot-x-range -1 count stop-nodes with [who > 0]
  ask stop-nodes with [shape != "square"] [plotxy id n-boarded]

  ; Create alighting histogram
  set-current-plot "n-alighted-histogram"
  clear-plot
  set-plot-x-range -1 count stop-nodes with [who > 0]
  ask stop-nodes with [shape != "square"] [plotxy id n-alighted]

  ; Update stop labels with booking counts
  ask stop-nodes [ ifelse (bookings = 0) [ set label "" ][ set label bookings ] ]

  ; Hide rejected users after some time
  ask past-users with [(status = "rejected")] [ if (time - request-time > 180) [ hide-turtle ] ]

  ; Update average load factor
  carefully [ set time-avg-load-factor time-avg-load-factor + mean [length on-board-list] of vehicles ] []
end

; Export simulation results to file
to export-outputs
  ; Get statistics from past users
  let pusr past-users
  let passengers pusr with [ride-time > 0]
  let twk (mean [walking-time] of passengers)
  let twt (mean [waiting-time] of passengers)
  let trd (mean [ride-time] of passengers)
  let rejusr pusr with [status = "rejected"]
  let nu count pusr with [status != "rejected"]

  ; Calculate performance indicators
  let pax-disutility (wgt-wait * twt + wgt-walk * twk + wgt-ride * trd) / 60
  let user-disutility (wgt-wait * mean [waiting-time / 60] of pusr + wgt-walk * mean [walking-time / 60] of pusr + wgt-ride * mean [ride-time / 60] of pusr)
  let transport-power (3.6 * ((count passengers) * sum [ride-distance] of passengers) / (sum [ride-time] of passengers))
  let puc ((wgt-wait * twt + wgt-walk * twk + wgt-ride * trd) * VoT / 3600)
  let ouc (((total-travel-distance / 1000) * cost-km) + ((count vehicles) * ((end-sim-time - start-sim-time) / 3600) * cost-h)) / (count passengers)

  ; Get top boarding/alighting nodes
  let pudo-list sort-on [(-1) * (n-boarded + n-alighted)] stop-nodes
  let boarded-alighted-list []
  let c 0
  repeat 1 [
    ask item c pudo-list [ set boarded-alighted-list lput (list id n-boarded n-alighted) boarded-alighted-list ]
    set c c + 1
  ]

  ; Update passenger load profile statistics
  update-pax-load-profile

  ; Select output file based on scenario
  (ifelse
    scenario = "FRT 1" [
      file-open (word "data-output-FRT-1.txt") ]
    scenario = "FRT 2" [
      file-open (word "data-output-FRT-2.txt") ]
    scenario = "DRT 1" [
      file-open (word "data-output-DRT-1.txt") ]
    scenario = "DRT 2" [
      file-open (word "data-output-DRT-2.txt") ]
  )

  ; Write simulation parameters and results to file
  file-print (word "Date and Time," date-and-time)
  file-print (word "Seed," rseed)
  file-print (word "DEMAND PARAMETERS")
  file-print (word "Demand Rate [pax/h]," demand-rate)
  file-print (word "SUPPLY PARAMETERS,")
  file-print (word "Number of Lines," length line-trip-list)
  file-print (word "Number of vehicles," count vehicles)
  file-print (word "Bus Cruising speed [Km/h]," vehicle-speed)
  file-print (word "USER-RELATED OUTPUTS")
  file-print (word "# tot Requests (NR)," n-tot-users)
  file-print (word "% Accepted Requests," precision (100 * n-of-accepted / (n-of-accepted + n-of-rejected)) 2)
  file-print (word "% Rejected Requests," precision (100 * n-of-rejected / (n-of-accepted + n-of-rejected)) 2)
  file-print (word "% Walking Users (NWK)," precision (100 * n-tot-walking / count pusr) 2)
  file-print (word "# passengers (NPAX)," (count passengers))
  file-print (word "% Transfers," precision (100 * n-of-transfers / n-of-accepted) 2)
  file-print (word "% Delayed Requests," precision (100 * n-of-delayed / n-of-accepted) 2)
  file-print (word "Avg Pre-trip Time (APTT) [min]," precision ((mean [pre-trip-time] of passengers) / 60) 2)
  file-print (word "Avg Walking Time (AWKT) [min]," precision (twk / 60) 2)
  file-print (word "Avg Waiting Time (AWTT) [min]," precision (twt / 60) 2)
  file-print (word "Avg Ride Time (ART) [min]," precision (trd / 60) 2)
  file-print (word "Avg Total Travel Time (ATT) [min]," precision ((twk + twt + trd) / 60) 2)
  file-print (word "Avg Penalty Time (PNT) [s]," precision (mean [(compute-distance self destination * m/p / ped-speed)] of rejusr) 0)
  file-print (word "Avg Time Stretch," precision (mean [time-stretch] of passengers) 2)
  file-print (word "Avg Passenger Disutility," precision pax-disutility 2)
  file-print (word "Avg User Disutility," precision user-disutility 2)
  file-print (word "OPERATOR-RELATED OUTPUTS")
  file-print (word "Total Driven Distance [Km]," precision (total-travel-distance / 1000) 1)
  file-print (word "Avg Route Distance [Km]," precision (total-travel-distance / (1000 * tot-n-of-trips)) 2)
  file-print (word "Total Energy Consumption [kWh]," precision total-energy-use 1)
  file-print (word "Avg Energy Cons. per Cycle [kWh]," precision (total-energy-use / tot-n-of-trips) 2)
  file-print (word "Avg Travel time [min]," precision (total-travel-time / tot-n-of-trips / 60) 1)
  file-print (word "Avg Vehicle Occupancy," precision ((count passengers) * trd / total-travel-time) 2)
  file-print (word "Transport Intensity (TI) [km/pax]," precision ((total-travel-distance / 1000) / (count passengers)) 2)
  file-print (word "Transport Power [kpax-km/h]," precision (transport-power / 1000) 2)
  file-print (word "Commercial Speed [Km/h]," precision (3.6 * total-travel-distance / total-travel-time) 2)
  file-print (word "n. boarded at terminal," item 1 first boarded-alighted-list)
  file-print (word "n. alighted at terminal," item 2 first boarded-alighted-list)
  file-print (word "ECONOMIC INDICATORS")
  file-print (word "Passenger Unit Cost [€/pax]," precision puc 2)
  file-print (word "Operator Unit Cost [€/pax]," precision ouc 2)
  file-print (word "Total Unit Cost [€/pax]," precision (puc + ouc) 2)
  file-print (word "Gini Index," precision (GINI-index nu) 3)
  file-print (word "PASSENGER LOAD PROFILES")

  ; Write passenger load profiles for each line
  let ll 0 repeat length pax-load-profile [
    let plp-l (word "LINE " (item ll line-name-list) ",")
    foreach (item ll pax-load-profile) [
      [plp-n] -> set plp-l insert-item (length plp-l) plp-l (word (first plp-n) "," (item 1 plp-n) "," (item 2 plp-n) ",")
    ]
    file-print bl plp-l
    set ll ll + 1
  ]
  file-print "****************************************************"

  file-close
end

; Update passenger load profiles across all trips
to update-pax-load-profile
  ; Normalize load profiles (make sure all have same stop sequence)
  let l 0
  repeat length pax-load-profile [
    let list-l item l pax-load-profile
    let m 0

    repeat length list-l [
      let list-m item m list-l
      let stop-list-trip-m bl (item m (item l line-trip-list))
      let n 0

      repeat length stop-list-trip-m [
        let sn0 0
        carefully [ set sn0 first (item n list-m) ] [ set sn0 nobody ]
        let sn first (item n stop-list-trip-m)

        ; Insert empty entries for stops with no activity
        if sn0 != sn [ set list-m insert-item n list-m (list sn 0 0) ]
        set n n + 1
      ]

      set list-l replace-item m list-l list-m
      set m m + 1
    ]

    set pax-load-profile replace-item l pax-load-profile list-l
    set l l + 1
  ]

  ; Sum up load profiles for each line across all trips
  set l 0
  repeat length pax-load-profile [
    let plp-l first (item l pax-load-profile)
    let m 0

    repeat length (item l pax-load-profile) [
      let list-m (item m (item l pax-load-profile))
      let n 0

      repeat length list-m [
        let n-pu item 1 (item n list-m)
        let n-do item 2 (item n list-m)
        let plp-l-n item n plp-l
        let n0-pu item 1 plp-l-n
        let n0-do item 2 plp-l-n

        ; Add boarding/alighting counts from this trip to line total
        set plp-l-n replace-item 1 plp-l-n (n0-pu + n-pu)
        set plp-l-n replace-item 2 plp-l-n (n0-do + n-do)
        set plp-l replace-item n plp-l plp-l-n
        set n n + 1
      ]

      set m m + 1
    ]

    set pax-load-profile replace-item l pax-load-profile plp-l
    set l l + 1
  ]
end

; Calculate Gini index to measure equity in travel time distribution
to-report GINI-index [nu]
  ; Get time stretch values for all users
  let time-user-list []
  ask past-users with [status != "rejected"] [ set time-user-list lput time-stretch time-user-list ]
  let sum-time-users (sum time-user-list)

  ; Sort travel times in ascending order
  let ordered-time-user-list sort-by < time-user-list
  let cumulative-difference-list []

  ; Apply Gini index formula
  let i 1
  repeat length ordered-time-user-list [
    let ti item (i - 1) ordered-time-user-list  ; Since i starts from 1 not 0
    set cumulative-difference-list lput ((nu + 1 - i) * ti) cumulative-difference-list
    set i i + 1
  ]

  ; Return Gini coefficient
  report (((nu + 1) / nu) - (2 / nu) * (sum cumulative-difference-list / sum-time-users))
end

; Draw a route on the map
to draw-route [stoplist nl tthickness]
  ; Clear previous route with same color
  ask streets with [color = (item nl color-list)] [
    set color 28
    set thickness 0
  ]

  ; Draw the route followed by the line
  let lastnode 0
  let i 0

  repeat (length stoplist - 1) [
    let s1 first (item i stoplist)
    let s2 first (item (i + 1) stoplist)

    ; Get path between consecutive stops
    let nodelist-i path-between-stops s1 s2 lastnode
    set lastnode item 1 (reverse nodelist-i)

    ; Highlight each street segment in the path
    let j 0
    repeat (length nodelist-i - 1) [
      let n1 item j nodelist-i
      let n2 item (j + 1) nodelist-i

      ask one-of streets with [end1 = n1 and end2 = n2] [
        set color (item nl color-list)
        set thickness tthickness
      ]

      set j j + 1
    ]

    set i i + 1
  ]
end

; Get the path (list of nodes) between two stops
to-report path-between-stops [s1 s2 lastnode]
  let id1 [ID] of s1
  let id2 [ID] of s2
  let nodelist 0

  ; Choose appropriate path based on last node (to avoid backtracking)
  ifelse (item 1 (item id2 (item id1 stop-link-list-1))) != lastnode [
    set nodelist (bl (item id2 (item id1 stop-link-list-1)))
  ][
    set nodelist (bl (item id2 (item id1 stop-link-list-2)))
  ]

  report nodelist
end

; Calculate the distance between two stops
to-report distance-between-stops [s1 s2 lastnode]
  let id1 [ID] of s1
  let id2 [ID] of s2
  let dist 0

  ; Choose appropriate distance based on last node
  ifelse (item 1 (item id2 (item id1 stop-link-list-1))) != lastnode [
    set dist (last (item id2 (item id1 stop-link-list-1)))
  ][
    set dist (last (item id2 (item id1 stop-link-list-2)))
  ]

  report dist
end

; Calculate travel time between two stops
to-report time-between-stops [s1 s2 lastnode]
  let id1 [ID] of s1
  let id2 [ID] of s2
  let nodelist 0

  ; Get the node path between stops
  ask s1 [
    ifelse (item 1 (item id2 (item id1 stop-link-list-1))) != lastnode [
      set nodelist (bl (item id2 (item id1 stop-link-list-1)))
    ][
      set nodelist (bl (item id2 (item id1 stop-link-list-2)))
    ]
  ]

  ; Calculate travel time based on street segments and speed
  let traveltime 0
  let i 0

  repeat (length nodelist - 1) [
    ask one-of streets with [end1 = (item i nodelist) and end2 = (item (i + 1) nodelist)] [
      let actual-speed min (list maxspeed vehicle-speed)
      set traveltime traveltime + (street-length / (actual-speed / 3.6))
    ]
    set i i + 1
  ]

  report traveltime
end

; Extract a list of stops from a trip
to-report report-stoplist [trip-m timeflag includeDRTstop?]
  ; Remove vehicle ID if present
  if not is-list? (last trip-m) [ set trip-m (bl trip-m) ]

  let mystoplist []
  let n 0

  repeat length trip-m [
    let stop-n item n trip-m
    let sn (first stop-n)

    ; Include stop if it's fixed (X=1) or we want DRT stops too
    if (item 3 stop-n) = 1 or includeDRTstop? [
      ifelse timeflag [
        set mystoplist lput (list sn (item 1 stop-n)) mystoplist  ; Include time info
      ][
        set mystoplist lput sn mystoplist  ; Just the stop
      ]
    ]

    set n n + 1
  ]

  report mystoplist
end

; Extract a list of streets for a route based on stops
to-report report-route [stoplist]
  let myroute []
  let tabu-node 0
  let n 0

  repeat (length stoplist - 1) [
    let s0 first (item n stoplist)
    let s1 first (item (n + 1) stoplist)

    if s0 != s1 [
      ; Get path between consecutive stops
      let path-n (path-between-stops s0 s1 tabu-node)
      let s 0

      ; Add each street segment to route
      repeat (length path-n - 1) [
        let n0 (item s path-n)
        let n1 (item (s + 1) path-n)
        set myroute lput one-of streets with [end1 = n0 and end2 = n1] myroute
        set s s + 1
      ]

      set tabu-node (item (s - 1) path-n)
    ]

    set n n + 1
  ]

  report myroute
end

; Calculate distance between two agents/patches
to-report compute-distance [a1 a2]
  ; Direct distance calculation
  let ddistance 0
  ask a1 [ set ddistance distance a2 ]
  report ddistance

  ; Alternative: Manhattan distance calculation (commented out)
  ; let xx1 0 let yy1 0
  ; let xx2 0 let yy2 0
  ; ifelse is-turtle? a1 [ set xx1 [xcor] of a1 set yy1 [ycor] of a1 ] [ set xx1 [pxcor] of a1 set yy1 [pycor] of a1]
  ; ifelse is-turtle? a2 [ set xx2 [xcor] of a2 set yy2 [ycor] of a2 ] [ set xx2 [pxcor] of a2 set yy2 [pycor] of a2]
;  report abs (xx1 - xx2) + abs (yy1 - yy2)

end

to manhattan-heading [target]

  let xx 0 let yy 0
  let xtar 0 let ytar 0
  ifelse is-turtle? target [ set xtar [xcor] of target set ytar [ycor] of target ] [ set xtar [pxcor] of target set ytar [pycor] of target]
  (ifelse
    abs (xcor - xtar) > (ped-speed / m/p) and abs (ycor - ytar) > (ped-speed / m/p)
    [ set xx xcor set yy ytar ]
    abs (xcor - xtar) < (ped-speed / m/p) and abs (ycor - ytar) > (ped-speed / m/p)
    [ set xx xcor set yy ytar ]
    abs (xcor - xtar) > (ped-speed / m/p) and abs (ycor - ytar) < (ped-speed / m/p)
    [ set xx xtar set yy ytar ]
    abs (xcor - xtar) < (ped-speed / m/p) and abs (ycor - ytar) < (ped-speed / m/p)
    [ ]
    )
  set heading towardsxy xx yy

end

to Create-streets

ifelse mouse-inside?
[
  let first-click false
  let new-street false
  if first-node = nobody [set first-click true]
  if first-click and not mouse-clicked
  [
    ifelse "yes" = user-one-of "New street?" ["no" "yes"]
    [
      type "***** click on the map to create the first node *****"
      set new-street true
    ]
    [
      type "***** click on the first node *****"
    ]
    ifelse new-street
    [
      while [not mouse-clicked]
      [
        if mouse-down? and not flag-link
        [
          create-nodes 1
          [
            set shape "circle"
            set color orange
            set size 1
            setxy mouse-xcor mouse-ycor
          ]
          ask patch round mouse-xcor round mouse-ycor
          [
            if any? turtles-on (patches in-radius 2) [set first-node one-of turtles-on (patches in-radius 2)]
          ]
          set mouse-clicked true
          set flag-link true
          set first-click false
          reset-timer
        ]
        display
      ]
    ]

    [
      while [not mouse-clicked]
      [
        if mouse-down? and not flag-link
        [
          ask patch round mouse-xcor round mouse-ycor
          [
            if any? turtles-on (patches in-radius 1) [set first-node one-of turtles-on (patches in-radius 1)]
          ]
          set mouse-clicked true
          set flag-link true
          set first-click false
          reset-timer
        ]
      ]
    ]
  ]
  if not first-click
  [
    if mouse-down? and timer > 0.5
    [
      ask patch round mouse-xcor round mouse-ycor
      [
        ifelse any? turtles-on (patches in-radius 1)
        [
          set second-node one-of turtles-on (patches in-radius 1)
        ]
        [
          sprout-nodes 1
          [
            set shape "circle"
            set color orange
            set size 1
            setxy mouse-xcor mouse-ycor
          ]
          ask patch round mouse-xcor round mouse-ycor
          [
            if any? turtles-on (patches in-radius 1) [set second-node one-of turtles-on (patches in-radius 1)]
          ]
        ]
      ]
      set flag-link false
      ask first-node [create-street-to second-node [set color 26 set shape "street" set label-color black set street-length link-length * m/p]]
      if (STREET-TYPE = "TWO-WAY") [ask second-node [create-street-to first-node [set color 26 set shape "street" set label-color black set street-length link-length * m/p]]]
      ask patch round mouse-xcor round mouse-ycor
      [
        if any? turtles-on (patches in-radius 1) [set first-node one-of turtles-on (patches in-radius 1)]
      ]
      set flag-link true
      reset-timer
    ]
    display
  ]
]
[
  set first-node nobody
  set second-node nobody
  set mouse-clicked false
  set flag-link false
  wait 1
  if not mouse-inside? [reset-timer stop]
]

end

to make-link

if mouse-down? and not flag-link and timer > 0.5
[
    ask patch round mouse-xcor round mouse-ycor
    [
      if any? turtles-on (patches in-radius 2) [set first-node one-of turtles-on (patches in-radius 2)]
    ]
    set flag-link true
    set mouse-clicked true
    reset-timer
]

if timer > 0.5 and flag-link
[
  if mouse-down?
  [
    ask patch round mouse-xcor round mouse-ycor
    [
      if any? turtles-on (patches in-radius 2) [set second-node one-of turtles-on (patches in-radius 2)]
    ]
    set flag-link false
    ask first-node [create-street-to second-node [set color 12 set shape "street" set label-color black set street-length link-length * m/p]]
    if (STREET-TYPE = "TWO-WAY") [ask second-node [create-street-to first-node [set color 12 set shape "street" set label-color black set street-length link-length * m/p]]]
    reset-timer
  ]
]
display

end

to delete-link

if mouse-down? and not flag-link and timer > 0.5
[
    ask patch round mouse-xcor round mouse-ycor
    [
      if any? turtles-on (patches in-radius 2) [set first-node one-of turtles-on (patches in-radius 2)]
    ]
    set flag-link true
    set mouse-clicked true
    reset-timer
]

if timer > 0.5 and flag-link
[
  if mouse-down?
  [
    ask patch round mouse-xcor round mouse-ycor
    [
        if any? turtles-on (patches in-radius 2) [set second-node one-of turtles-on (patches in-radius 2)]
    ]
    set flag-link false
    ask streets with [(first-node = end1 and second-node = end2) or (first-node = end2 and second-node = end1)] [die]
    reset-timer
  ]
]
display

end

to move-node

    ;; detects a single mouse click
    if not mouse-clicked and mouse-down?
    [
       ;; detects if this single mouse click is soon after another
       ifelse timer <= 0.25
       [  set mouse-double-click true ]
       [  set mouse-double-click false]

       ;; everytime the mouse is clicked, the timer starts
       reset-timer

       set mouse-clicked true

       ;; if there are turtles at the current mouse location, then pick one
       ;; this if statement keeps the program from having problems if
       ;; you click on an empty patch
       ask patch round mouse-xcor round mouse-ycor
       [  if any? turtles-on (patches in-radius 1)
          [set clicked-node one-of turtles-on (patches in-radius 1)]
       ]
    ]

    ;; if a turtle is only clicked, then it moves to match the mouse
    if is-agent? clicked-node and not mouse-double-click
    [  ask clicked-node
       [ setxy mouse-xcor mouse-ycor ]
    ]


    ;; if a turtle has been double clicked
;    if is-agent? clicked-node and mouse-double-click
;    [  wait .15
;       ;; this is to give time for mouse-down? to reset
;       ;; this is important because user-message can interrupt mouse-down?
;       ;; and cause it to not reset to false
;       ask clicked-node [user-message (word "degree:" (count link-neighbors))]
;       reset-timer
;       set mouse-double-click false
;       set clicked-node nobody
;    ]


    ;; detects raising the mouse button
    if mouse-clicked and not mouse-down?
    [  set mouse-clicked false
       if is-agent? clicked-node
       [ set clicked-node nobody]
    ]
    display

end

to make-stop-nodes

  if mouse-down?
  [
    if timer > 0.5
    [
      ask patch mouse-xcor mouse-ycor
      [
        ifelse any? nodes in-radius 2
        [
          ask one-of nodes in-radius 2
          [
            set breed stop-nodes
            set shape "circle"
            set color 114
            set size 1.5
            set label-color black
            reset-timer
          ]
        ]
        [
          if any? stop-nodes in-radius 2
          [
            ask one-of stop-nodes in-radius 2
            [
              set breed nodes
              set shape "circle"
              set color orange
              set size 1
              reset-timer
            ]
          ]
        ]
      ]
    ]
  display
  ]

end

to delete-nodes

  if mouse-down?
  [
    ask patch round mouse-xcor round mouse-ycor
    [
      if any? turtles-on (patches in-radius round 1) [ask turtles-on (patches in-radius round 1) [die]]
    ]
  ]
  display

end

to IMPORT-DATASET

  let GIS-dataset gis:load-dataset "Caltanissetta_zones.shp"
;  gis:set-world-envelope-ds (gis:envelope-union-of (gis:envelope-of GIS-dataset))
  gis:set-transformation-ds (list 14.0071 14.1046 37.4555 37.5135) (list min-pxcor max-pxcor min-pycor max-pycor)

  clear-drawing

  gis:apply-coverage GIS-dataset "ID" IDsez

  gis:set-drawing-color grey
  gis:draw GIS-dataset 1

  ask stop-nodes with [size < 3] [ set color 4 ]

  ask patches [
    if not (IDsez <= 0 or IDsez >= 0) [ set IDsez -1 ]
  ]

  clear-drawing

end

to IMPORT-STOPS-SHAPEFILE

  let stop-dataset gis:load-dataset "CL_STOPS.shp"
  foreach gis:feature-list-of stop-dataset [
    vector-feature ->
;    output-show gis:location-of (first (first (gis:vertex-lists-of vector-feature)))
    let coord-tuple gis:location-of (first (first (gis:vertex-lists-of vector-feature)))
    let long-coord item 0 coord-tuple
    let lat-coord item 1 coord-tuple
    create-stop-nodes 1 [
      setxy long-coord lat-coord
      set shape "circle"
      set color 114
      set size 1.5
      set label-color black
    ]
  ]

end

to SETUP-STOP-NODES

  ;nw:set-context (turtle-set nodes stop-nodes) streets
  ;execute this command only when stop nodes are added or removed
  ask nodes [ set ID -1 ]
  ask stop-nodes [ set ID -1 ]
  let terminal-node-list (list stop-node 0) ;terminal - capolinea "Piazza Roma - Stazione"
  let iid 0
  foreach terminal-node-list [
    [ttnl] -> ask ttnl [
      if ID < 0 [
        set shape "square"
        set ID iid
        set iid iid + 1
      ]
    ]
  ]
  let ordered-stops sort-on [who] stop-nodes with [shape != "square" and any? out-link-neighbors]
  foreach ordered-stops [
    [ost] -> ask ost [
      set ID iid
      set iid iid + 1
    ]
  ]
  ask nodes with [any? out-link-neighbors] ;;;modify when the network is all connected
  [
    set ID iid
    set iid iid + 1
  ]
  ;initialize stop-link-list
  ;level 1: [ stop-link-list ] -> [ S_0 ], [ S_1 ] ... [ S_i ] ... [ S_N ]
  ;level 2: -> [...[ S_i ]...] -> [ S_i0 ], [ S_i1 ] ... [ S_ij ] ... [ S_iN ]
  ;level 3: -> [...[...[ S_ij ]...]...] -> [ S_i, n_1, ... n_k, ... S_j, dist_ij ]
  set stop-link-list-1 []
  set stop-link-list-2 []
  set ordered-stops sort-on [ID] stop-nodes with [any? out-link-neighbors]
  let i 0
  repeat length ordered-stops [
    ; level 1
    let S_i one-of stop-nodes with [ID = i]
    let path-1-i []
    let path-2-i []
    let j 0
    repeat length ordered-stops [
      ;level 2
      let S_j one-of stop-nodes with [ID = j]
      ifelse i != j
      [
        let n 0 ;number of double (in/out) connections  between stop-node i and any neighbor node j
        ask S_i [
          ask out-street-neighbors [
            if out-street-neighbor? S_i [ set n n + 1 ]
          ]
          ;level 3
          let sublist-1 (nw:turtles-on-weighted-path-to S_j street-length)
          let ddistance (precision (nw:weighted-distance-to S_j street-length) 1)
          set sublist-1 lput ddistance sublist-1
          let sublist-2 []
          let next-node item 1 sublist-1
          set path-1-i lput sublist-1 path-1-i
          ;level 3
          ifelse n > 0
          [
            let min-dist 1000000
            let ddist min-dist
            ;tra tutti i possibili "next node" trovo quello che minimizza la distanza verso il S_j
            let tabu-list remove-duplicates (sentence S_i S_j (sort out-street-neighbors))
            let nodelist sort nodes
            let node2 nobody
            let list1 []
            let list2 []
            let dist1 0
            let dist2 0
            let k 0
            repeat length nodelist [
              set node2 item k nodelist
              set list1 (nw:turtles-on-weighted-path-to node2 street-length)
              ask node2 [ set list2 (nw:turtles-on-weighted-path-to S_j street-length) ]
              if ((item 1 (reverse list1)) != (item 1 list2)) and (item 1 list1 != next-node) [
                set dist1 (nw:weighted-distance-to node2 street-length)
                ask node2 [ set dist2 (nw:weighted-distance-to S_j street-length) ]
                set ddist (precision (dist1 + dist2) 1)
                if ddist < min-dist [
                  set sublist-2 (sentence list1 (bf list2))
                  set sublist-2 lput ddist sublist-2
                  set min-dist ddist
                ]
              ]
              set k k + 1
            ]
            set path-2-i lput sublist-2 path-2-i
            ;            ask one-of streets with [end1 = S_i and end2 = next-node] [ set street-length street-length + dd ]
            ;            let sublist-2 (nw:turtles-on-weighted-path-to S_j street-length)
            ;            set sublist-2 lput (precision (nw:weighted-distance-to S_j street-length) 1) sublist-2
            ;            set path-2-i lput sublist-2 path-2-i
            ;            ask streets with [street-length > dd] [ set street-length street-length - dd ]
          ]
          [ set path-2-i lput [] path-2-i ] ;or lput sublist-1
        ] ;end level 3
      ]
      [
        set path-1-i lput (list S_i 0) path-1-i
        set path-2-i lput (list S_i 0) path-2-i
      ]
      set j j + 1
      ;end level 2
    ]
    set stop-link-list-1 lput path-1-i stop-link-list-1
    set stop-link-list-2 lput path-2-i stop-link-list-2
    set i i + 1
    ;end level 1
  ]

end

;  let who-stop-list []
;  (ifelse
;    scenario = "FRT short" [
;      set who-stop-list [
;        [ 0 7 9 98 81 22 92 94 93 107 119 120 118 141 134 133 132 131 140 135 128 127 97 5 100 82 36 38 37 32 24 77 35 145 144 74 76 71 30 103 169 0 ]
;        [ 0 7 6 97 5 98 100 81 82 20 21 19 99 116 117 115 50 52 51 53 23 95 96 18 33 34 24 77 35 146 152 148 151 27 103 169 0 ]
;        [ 0 7 143 142 163 164 88 89 90 111 110 1 105 29 28 78 26 25 165 106 86 85 84 83 87 0 ]
;        [ 0 7 6 97 5 98 100 81 173 174 171 170 172 149 150 145 144 162 153 69 12 70 157 156 159 147 17 16 80 167 168 166 4 30 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 59 56 57 58 54 60 39 91 55 112 113 114 64 63 68 108 109 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 147 146 152 148 151 27 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 147 146 152 148 151 27 103 169 0 ]
;      ]
;    ]
;    scenario = "FRT long" [
;      set who-stop-list [
;        [ 0 7 9 98 81 22 92 94 93 107 119 120 118 130 136 137 14 3 15 121 2 13 79 139 138 129 141 134 133 132 131 140 135 128 127 97 5 100 82 36 38 37 32 24 77 35 145 144 74 76 71 30 103 169 0 ]
;        [ 0 7 6 97 5 98 100 81 82 20 21 19 99 116 67 65 11 66 117 115 50 52 51 53 23 95 96 18 33 34 24 77 35 146 152 148 151 27 103 169 0 ]
;        [ 0 7 143 142 163 164 88 89 90 111 110 1 105 29 28 78 26 25 165 106 86 85 84 83 87 0 ]
;        [ 0 7 6 97 5 98 100 81 173 174 171 170 172 149 150 145 144 162 153 69 12 161 158 155 160 154 70 157 156 159 147 17 16 80 167 168 166 4 30 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 59 56 57 58 54 60 101 122 123 124 61 62 39 91 55 112 113 114 64 63 68 108 109 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 162 153 69 12 161 158 155 160 154 70 157 156 159 147 146 152 148 151 27 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 41 8 43 44 47 46 49 45 42 40 48 147 146 152 148 151 27 103 169 0 ]
;      ]
;    ]
;    scenario = "FRT new" [
;      set who-stop-list [
;        [ 0 7 9 98 81 22 92 94 93 107 119 120 118 130 136 137 14 3 15 121 2 13 79 139 138 129 141 134 133 132 131 140 135 128 127 97 5 100 82 36 38 37 32 24 77 35 145 144 74 76 71 30 103 169 0 ]
;        [ 0 7 6 97 5 98 100 81 82 20 21 19 99 116 67 65 11 66 117 115 50 52 51 53 23 95 96 18 33 34 24 77 35 146 152 148 151 27 103 169 0 ]
;        [ 0 7 143 142 163 164 88 89 90 111 110 1 105 29 28 78 26 25 165 106 86 85 84 83 87 0 ]
;        [ 0 7 6 97 5 98 100 81 173 174 171 170 172 149 150 145 144 162 153 69 12 161 158 155 160 154 70 157 156 159 147 17 16 80 167 168 166 4 30 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 59 56 57 58 54 60 101 122 123 124 61 62 39 91 55 112 113 114 64 63 68 108 109 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 162 153 69 12 161 158 155 160 154 70 157 156 159 147 146 152 148 151 27 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 41 8 43 44 47 46 49 45 42 40 48 147 146 152 148 151 27 103 169 0 ]
;        [ 0 7 9 5 98 100 99 116 67 65 11 66 117 115 50 52 51 53 33 34 24 77 35 145 144 162 153 69 161 158 155 160 154 70 157 156 159 60 101 122 123 124 61 62 39 91 55 112 113 114 64 63 68 108 109 169 7 143 142 163 164 88 89 90 126 165 106 86 85 84 83 87 0 ] ;linea pomeridiana (sostitutiva linee 2-3-5-6)
;        [ 0 7 6 97 5 98 10 102 104 31 59 56 57 58 54 60 101 122 123 124 61 62 39 91 55 112 113 114 64 63 68 108 109 169 0 ] ;navetta SUD BALATE (uguale alla linea 5)
;        [ 0 7 9 5 98 100 99 116 117 115 50 52 51 53 33 34 24 77 35 145 144 162 153 69 161 158 155 160 154 70 157 156 159 147 146 152 148 151 27 103 169 0 ] ;navetta NORD OVEST REGIONE (mix linea 2 e linea 6)
;        [ 0 7 6 164 88 89 90 126 175 25 165 106 86 85 84 83 87 0 ] ;navetta EST SAN LUCA (simile alla linea 3)
;      ]
;    ]
;    scenario = "DRT 1" [
;      set who-stop-list [
;        [ 0 7 9 98 81 22 92 94 93 118 36 38 37 32 24 77 35 145 144 74 76 71 30 103 169 0 ]
;        [ 0 7 6 97 5 98 100 81 82 20 21 19 99 116 117 115 50 52 51 53 18 33 34 24 77 35 146 152 148 151 27 103 169 0 ]
;        [ 0 7 143 142 163 164 88 89 90 165 106 86 85 84 83 87 0 ]
;        [ 0 7 6 97 5 98 100 81 173 174 171 170 172 149 150 145 144 162 153 69 12 70 157 156 159 147 17 16 80 167 168 166 4 30 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 59 56 57 58 54 60 39 91 55 112 113 114 64 63 68 108 109 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 147 146 152 148 151 27 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 147 146 152 148 151 27 103 169 0 ]
;      ]
;    ]
;    scenario = "DRT 2" [
;      set who-stop-list [
;        [ 0 7 9 98 81 22 92 94 93 118 36 38 37 32 24 77 35 145 144 74 76 71 30 103 169 0 ]
;        [ 0 7 6 97 5 98 100 81 82 20 21 19 99 116 117 115 50 52 51 53 18 33 34 24 77 35 146 152 148 151 27 103 169 0 ]
;        [ 0 7 143 142 163 164 88 89 90 165 106 86 85 84 83 87 0 ]
;        [ 0 7 6 97 5 98 100 81 173 174 171 170 172 149 150 145 144 162 153 69 12 70 157 156 159 147 17 16 80 167 168 166 4 30 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 59 56 57 58 54 60 39 91 55 112 113 114 64 63 68 108 109 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 147 146 152 148 151 27 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 147 146 152 148 151 27 103 169 0 ]
;
;        [ 0 7 9 98 81 22 92 94 93 107 119 120 118 130 136 137 14 3 15 121 2 13 79 139 138 129 141 134 133 132 131 140 135 128 127 97 5 100 82 36 38 37 32 24 77 35 145 144 74 76 71 30 103 169 0 ]
;        [ 0 7 6 97 5 98 100 81 82 20 21 19 99 116 67 65 11 66 117 115 50 52 51 53 23 95 96 18 33 34 24 77 35 146 152 148 151 27 103 169 0 ]
;        [ 0 7 143 142 163 164 88 89 90 111 110 1 105 29 28 78 26 175 25 165 106 86 85 84 83 87 0 ]
;        [ 0 7 6 97 5 98 100 81 173 174 171 170 172 149 150 145 144 162 153 69 12 161 158 155 160 154 70 157 156 159 147 17 16 80 167 168 166 4 30 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 59 56 57 58 54 60 101 122 123 124 61 62 39 91 55 112 113 114 64 63 68 108 109 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 162 153 69 12 161 158 155 160 154 70 157 156 159 147 146 152 148 151 27 103 169 0 ]
;        [ 0 7 6 97 5 98 10 102 104 31 75 72 73 41 8 43 44 47 46 49 45 42 40 48 147 146 152 148 151 27 103 169 0 ]
;      ]
;    ]
;  )

;  file-print ""
;  file-write "Date and Time              " file-write date-and-time         file-print ""
;  file-print ""
;  file-write "Seed                       " file-write rseed                 file-print ""
;  file-write "DEMAND PARAMETERS          " file-print ""
;  file-write "Demand Rate [pax/h]        " file-write demand-rate           file-print ""
;  file-write "SUPPLY PARAMETERS          " file-print ""
;  file-write "Number of Lines            " file-write length line-trip-list file-print ""
;  file-write "Number of vehicles         " file-write count vehicles        file-print ""
;  file-write "Bus Cruising speed [Km/h]  " file-write vehicle-speed         file-print ""
;  file-print ""
;  file-write "USER-RELATED OUTPUTS              "
;  file-print ""
;  file-write "# tot Requests (NR)                " file-write n-tot-users                                                                  file-print ""
;  file-write "% Accepted Requests                " file-write precision (100 * n-of-accepted / (n-of-accepted + n-of-rejected)) 2          file-print ""
;  file-write "% Rejected Requests                " file-write precision (100 * n-of-rejected / (n-of-accepted + n-of-rejected)) 2          file-print ""
;  file-write "% Walking Users (NWK)              " file-write precision (100 * n-tot-walking / count pusr) 2                               file-print ""
;  file-write "# passengers (NPAX)                " file-write (count passengers)                                                           file-print ""
;  file-write "% Transfers                        " file-write precision (100 * n-of-transfers / n-of-accepted) 2                           file-print ""
;  file-write "% Delayed Requests                 " file-write precision (100 * n-of-delayed / n-of-accepted) 2                             file-print ""
;  file-write "Avg Pre-trip Time (APTT) [min]     " file-write precision ((mean [pre-trip-time] of passengers) / 60) 2                      file-print ""
;  file-write "Avg Walking Time (AWKT) [min]      " file-write precision (twk / 60) 2                                                       file-print ""
;  file-write "Avg Waiting Time (AWTT) [min]      " file-write precision (twt / 60) 2                                                       file-print ""
;  file-write "Avg Ride Time (ART) [min]          " file-write precision (trd / 60) 2                                                       file-print ""
;  file-write "Avg Total Travel Time (ATT) [min]  " file-write precision ((twk + twt + trd) / 60) 2                                         file-print ""
;  file-write "Avg Penalty Time (PNT) [s]         " file-write precision (mean [(compute-distance self destination * m/p / ped-speed)] of rejusr) 0      file-print "" ;;;penalty for being rejected proportional to the distance from the destination
;  file-write "Avg Time Stretch                   " file-write precision (mean [time-stretch] of passengers) 2                              file-print ""
;  file-write "Avg Passenger Disutility           " file-write precision pax-disutility 2                                                   file-print ""
;  file-write "Avg User Disutility                " file-write precision user-disutility 2                                                  file-print ""
;  file-write "OPERATOR-RELATED OUTPUTS           "
;  file-print ""
;  file-write "Total Driven Distance [Km]         " file-write precision (total-travel-distance / 1000) 1                                   file-print ""
;  file-write "Avg Route Distance [Km]            " file-write precision (total-travel-distance / (1000 * tot-n-of-trips)) 2                file-print ""
;  file-write "Total Energy Consumption [kWh]     " file-write precision total-energy-use 1                                                 file-print ""
;  file-write "Avg Energy Cons. per Cycle [kWh]   " file-write precision (total-energy-use / tot-n-of-trips) 2                              file-print ""
;  file-write "Avg Travel time [min]              " file-write precision (total-travel-time / tot-n-of-trips / 60) 1                        file-print ""
;  file-write "Avg Vehicle Occupancy              " file-write precision ((count passengers) * trd / total-travel-time) 2                   file-print ""
;  file-write "Transport Intensity (TI) [km/pax]  " file-write precision ((total-travel-distance / 1000) / (count passengers)) 2            file-print ""
;  file-write "Transport Power [kpax-km/h]        " file-write precision (transport-power / 1000) 2                                         file-print ""
;  file-write "Commercial Speed [Km/h]            " file-write precision (3.6 * total-travel-distance / total-travel-time) 2                file-print ""
;  file-write "n. boarded at terminal             " file-write item 1 first boarded-alighted-list                                           file-print ""
;  file-write "n. alighted at terminal            " file-write item 2 first boarded-alighted-list                                           file-print ""
;  file-write "ECONOMIC INDICATORS                "
;  file-print ""
;  file-write "Passenger Unit Cost [€/pax]        " file-write precision puc 2                                                              file-print ""
;  file-write "Operator Unit Cost [€/pax]         " file-write precision ouc 2                                                              file-print ""
;  file-write "Total Unit Cost [€/pax]            " file-write precision (puc + ouc) 2                                                      file-print ""
;  file-write "Gini Index                         " file-write precision (GINI-index nu) 3                                                  file-print ""
;  file-print ""
;  file-write "PASSENGER LOAD PROFILES            " file-print ""
;  let ll 0 repeat length pax-load-profile [
;  foreach (item ll pax-load-profile) [
;      [plp-n] -> file-write first plp-n file-write "," file-write item 1 plp-n file-write "," file-write item 2 plp-n file-write ","
;    ]
;    file-print ""
;    set ll ll + 1
;  ]
;  file-print ""
;  file-write "****************************************************"
;  file-print ""
@#$#@#$#@
GRAPHICS-WINDOW
300
10
1755
1105
-1
-1
3.61
1
15
1
1
1
0
0
0
1
-200
200
-150
150
0
0
1
ticks
30.0

BUTTON
106
10
199
56
SETUP
clear-output\nSETUP-SERVICE
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

BUTTON
753
1064
879
1097
MAKE STOP NODES
make-stop-nodes
T
1
T
OBSERVER
NIL
N
NIL
NIL
1

BUTTON
1172
1052
1308
1096
CREATE-STREETS
create-streets
T
1
T
OBSERVER
NIL
C
NIL
NIL
1

BUTTON
645
1064
751
1097
DELETE NODES
delete-nodes
T
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
539
1064
643
1097
MOVE NODES
move-node
T
1
T
OBSERVER
NIL
M
NIL
NIL
1

BUTTON
2
10
103
56
IMPORT MAP
clear-all\nimport-world \"Caltanissetta_world.txt\"ifelse (rseed = 0) [random-seed new-seed] [random-seed rseed]\nIMPORT-DATASET\ndisplay\nimport-drawing \"Caltanissetta_map_1600x1200.png\"
NIL
1
T
OBSERVER
NIL
0
NIL
NIL
1

BUTTON
309
1063
419
1097
EXPORT WORLD
if \"YES\" = user-one-of \"Are you sure?\" [\"NO\" \"YES\"] \n[\n  clear-drawing\n  export-world \"Caltanissetta_world.txt\"\n  import-drawing \"Caltanissetta_map_1600x1200.png\"\n]
NIL
1
T
OBSERVER
NIL
E
NIL
NIL
1

BUTTON
395
19
462
64
GIS Map 
clear-drawing\nif (MAP-VIEW = \"TAZ\") [\n  let maxID max [IDsez] of patches\n  let i 1\n  repeat maxID [\n    if any? patches with [IDsez = i] [\n      let ccolor random(140)\n      ask patches with [IDsez = i] [\n        ifelse IDsez > 0 \n        [ set pcolor ccolor ]\n        [ set pcolor 5 ]\n      ]\n    ]\n    set i i + 1\n  ]\n]\nask patches\n[\n  if not ( IDsez <= 0 or IDsez >= 0 )\n  [ set pcolor grey + 3]\n]\nif (MAP-VIEW = \"MAP\")\n[\n  import-drawing \"Caltanissetta_map_1600x1200.png\"\n  ;ask buildings [show-turtle]\n]
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
202
10
297
56
SIMULATION
GO if time = 100000 [stop]
T
1
T
OBSERVER
NIL
2
NIL
NIL
1

MONITOR
1081
17
1166
62
time (s)
time
0
1
11

SLIDER
3
145
297
178
demand-rate
demand-rate
100
5000
600.0
50
1
pax/day
HORIZONTAL

MONITOR
1619
744
1746
789
% rejected
100 * n-of-rejected / (n-of-accepted + n-of-rejected)
1
1
11

MONITOR
1490
744
1617
789
% accepted
100 * n-of-accepted / (n-of-accepted + n-of-rejected)
1
1
11

SLIDER
3
182
297
215
max-waiting-time
max-waiting-time
0
1800
1200.0
30
1
s
HORIZONTAL

MONITOR
1490
650
1617
695
n-tot-users
n-tot-users
0
1
11

PLOT
4
256
297
530
user-experience
time (hr)
n. of users
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -13840069 true "" ""
"R" 1.0 0 -2674135 true "" ""
"D" 1.0 0 -8630108 true "" ""

PLOT
4
815
298
1108
average-vehicle-occupancy
time (min)
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"max-cap" 1.0 0 -2674135 true "" ""

MONITOR
910
17
997
62
time (h)
time / 3600
2
1
11

MONITOR
999
17
1079
62
time (min)
time / 60
1
1
11

PLOT
1760
553
2057
833
n-boarded-histogram
id-stop-nodes
individuals
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
1760
839
2057
1105
n-alighted-histogram
id-stop-nodes
individuals
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
3
538
298
808
average-load-histogram
VEHICLE ID
NIL
0.0
10.0
0.0
10.0
false
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""
"max-cap" 1.0 0 -2674135 true "" ""

CHOOSER
1313
1051
1430
1096
street-type
street-type
"ONE-WAY" "TWO-WAY"
0

SLIDER
2
107
297
140
rseed
rseed
0
100
4.0
1
1
NIL
HORIZONTAL

BUTTON
306
18
385
91
1 step
GO
NIL
1
T
OBSERVER
NIL
3
NIL
NIL
1

SLIDER
3
219
297
252
vehicle-speed
vehicle-speed
10
40
30.0
1
1
Km/h
HORIZONTAL

TEXTBOX
1525
619
1718
639
USER-RELATED OUTPUTS
16
0.0
1

MONITOR
1490
1008
1617
1053
TDD [km]
total-travel-distance / 1000
1
1
11

MONITOR
1490
697
1617
742
NAP (pax)
n-of-accepted
1
1
11

MONITOR
1619
650
1746
695
Time Stretch
mean [time-stretch] of users with [ride-time > 0]
2
1
11

MONITOR
1490
791
1617
836
% transfers
100 * n-of-transfers / n-of-accepted
1
1
11

MONITOR
1490
885
1617
930
ART (min)
mean [ride-time / 60] of users with [ride-time > 0]
2
1
11

MONITOR
1619
838
1746
883
AWKT (min)
mean [walking-time / 60] of users with [ride-time > 0]
2
1
11

MONITOR
1490
838
1617
883
AWTT (min)
mean [waiting-time / 60] of users with [ride-time > 0]
2
1
11

MONITOR
1619
885
1746
930
ATTT (min)
mean [tot-travel-time / 60] of users with [ride-time > 0]
2
1
11

MONITOR
1619
1055
1746
1100
CS (km/h)
time-avg-commercial-speed / tot-n-of-trips
1
1
11

MONITOR
1619
791
1746
836
%-delayed
100 * n-of-delayed / n-of-accepted
1
1
11

MONITOR
1619
697
1746
742
REJ (pax)
n-of-rejected
17
1
11

MONITOR
1619
1008
1746
1053
AVD (km)
(total-travel-distance / (1000 * sum [n-of-trips] of vehicles))
2
1
11

TEXTBOX
1494
972
1743
1012
OPERATOR-RELATED OUTPUTS
16
0.0
1

MONITOR
1490
1055
1617
1100
AVO
(time-avg-load-factor / time)
2
1
11

BUTTON
439
1064
537
1097
DELETE LINKS
delete-link
T
1
T
OBSERVER
NIL
X
NIL
NIL
1

BUTTON
1611
21
1747
54
Stop Node Setup
SETUP-STOP-NODES
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
1764
13
2381
550
10

CHOOSER
468
19
560
64
MAP-VIEW
MAP-VIEW
"TAZ" "MAP"
1

BUTTON
308
162
467
206
Show stop labels
ifelse any? stop-nodes with [label = \"\"] and any? stop-nodes with [label != \"\"] \n[ ask stop-nodes [ set label \"\" ] ]\n[\nask stop-nodes [\n  ifelse label = \"\" [\n    set label-color black\n    set label who\n  ]\n  [\n    set label \"\"\n  ]\n]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
107
59
297
104
scenario
scenario
"FRT 1" "FRT 2" "DRT 1" "DRT 2"
2

BUTTON
307
105
467
150
Show Route
;call this command after the SETUP\nask streets\n[ \n  ifelse color = 26\n  [ set thickness 0 ]\n  [ set thickness 0.8]\n]\n\nlet nl (read-from-string user-input \"line ID ... \")\nlet tthickness 1.5\n\nask one-of vehicles with [nl = first (item n-of-trips v-trip-list)]\n[\n  let trip-num item 1 (item n-of-trips v-trip-list)\n  let thistrip item trip-num (item nl line-trip-list)\n  let stoplist report-stoplist thistrip true false\n  draw-route stoplist nl tthickness \n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
5
59
103
104
export-results
export-results
"YES" "NO"
1

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

bus
false
0
Polygon -16777216 false false 285 195 285 165 270 105 255 90 30 90 15 105 15 180 30 195 285 195
Polygon -7500403 true true 15 180 15 105 30 90 255 90 270 105 285 165 285 195 30 195 15 180 15 180
Circle -16777216 true false 30 165 60
Circle -16777216 true false 210 165 60
Circle -7500403 true true 45 180 30
Circle -7500403 true true 225 180 30
Rectangle -16777216 true false 30 105 75 150
Rectangle -16777216 true false 90 105 135 150
Rectangle -16777216 true false 150 105 195 150
Rectangle -16777216 true false 210 105 255 150

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
true
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

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

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

van
false
0
Polygon -7500403 true true 75 90 225 90 255 135 285 150 285 180 270 195 60 195 45 180 45 135 60 90
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 225 105 240 135 195 135 195 105
Circle -16777216 true false 219 174 42
Circle -16777216 true false 69 174 42
Circle -13345367 false false 69 174 42
Circle -13345367 false false 219 174 42
Polygon -7500403 false true 165 165
Polygon -7500403 true true 75 105
Polygon -7500403 true true 135 150
Polygon -16777216 true false 225 135
Polygon -16777216 true false 225 135
Polygon -16777216 true false 180 105 180 135 135 135 135 105 180 105
Polygon -16777216 true false 120 105 120 135 75 135 75 105 120 105
Polygon -16777216 false false 105 210 105 195

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="FRT" repetitions="1" runMetricsEveryStep="true">
    <setup>SETUP-SERVICE</setup>
    <go>GO</go>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;FRT 2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="demand-rate">
      <value value="600"/>
      <value value="900"/>
      <value value="1200"/>
      <value value="1500"/>
      <value value="1800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vehicle-speed">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-waiting-time">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rseed">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DRT" repetitions="1" runMetricsEveryStep="true">
    <setup>SETUP-SERVICE</setup>
    <go>GO</go>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;DRT 1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="demand-rate">
      <value value="600"/>
      <value value="900"/>
      <value value="1200"/>
      <value value="1500"/>
      <value value="1800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vehicle-speed">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-waiting-time">
      <value value="1200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rseed">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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

line
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0

street
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 165 150 225 285
@#$#@#$#@
0
@#$#@#$#@
