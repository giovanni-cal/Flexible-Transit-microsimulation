# Flexible-Transit-microsimulation
Summary of the NetLogo Transit Simulation
This NetLogo model simulates a multi-modal public transportation system that can operate in two different service modes:
Fixed Route Transit (FRT): Traditional public transport with fixed routes and schedules.
Demand Responsive Transit (DRT): Flexible service that adapts to user demand, made by fixed routes and optional detours available on Demand.

The model allows for testing different transit designs and operational strategies to optimize service quality, efficiency, and sustainability.

Key Components
Network Structure: Road network with nodes, streets, and designated stops
Transit Lines: Multiple transit lines with defined routes and schedules
Vehicles: Buses that follow routes and transport passengers
Users: Agents that travel from origin to destination using the transit system
Matching Algorithm: Logic for assigning users to optimal transit options

Main Processes
Setup Phase:
Initialize parameters and network
Import transit lines and schedules from files
Create vehicles and assign trips

Simulation Loop:
Update vehicle positions and status
Update user status (waiting, walking, riding)
Generate new travel demand based on time of day
Match new users to suitable transit options

Matching Algorithm:
Find nearby stops for origin and destination
Search for direct trips or trips with transfers
Calculate costs considering walking, waiting, and riding times
Choose lowest-cost option for each user

Performance Evaluation:
Track metrics like commercial speed, vehicle occupancy
Measure user experience (waiting times, travel times)
Calculate operational costs and energy consumption

Key Features:
Dual-Mode Operation: Can simulate both fixed and demand-responsive transit
Network Editor: Tools for creating and modifying the transportation network
GIS Integration: Import geographical data for zones and stops
Time Windows: Realistic scheduling with time constraints
Multi-Modal Trips: Supports trips combining transit and walking
Performance Analysis: Comprehensive metrics and visualizations
Equity Measurement: Gini index for travel time distribution
