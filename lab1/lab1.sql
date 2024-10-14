Table Vehicle {
  id INTEGER [pk, increment]
  registration_number VARCHAR(50) [unique]
  model VARCHAR(100)
  brand VARCHAR(100)
  year_of_manufacture YEAR
  status VARCHAR(50)
  vehicle_type_id INTEGER [ref: > VehicleType.id]
  capacity INTEGER
  load_capacity DECIMAL(10, 2)
  team_id INTEGER [ref: > Team.id]
}

Table VehicleType {
  id INTEGER [pk, increment]
  name VARCHAR(50) [unique]
  description TEXT
}

Table Driver {
  id INTEGER [pk, increment]
  name VARCHAR(100)
  license_number VARCHAR(50) [unique]
  employment_date DATE
  team_id INTEGER [ref: > Team.id]
}

Table Team {
  id INTEGER [pk, increment]
  name VARCHAR(100)
  foreman_id INTEGER [ref: > Foreman.id]
}

Table Foreman {
  id INTEGER [pk, increment]
  name VARCHAR(100)
}

Table Route {
  id INTEGER [pk, increment]
  name VARCHAR(100)
  start_location VARCHAR(100)
  end_location VARCHAR(100)
  distance DECIMAL(5, 2)
}

Table PassengerRecord {
  id INTEGER [pk, increment]
  vehicle_id INTEGER [ref: > Vehicle.id]
  route_id INTEGER [ref: > Route.id]
  date DATE
  passenger_count INTEGER
}

Table VehicleDriver {
  vehicle_id INTEGER [ref: > Vehicle.id]
  driver_id INTEGER [ref: > Driver.id]
  assignment_start_date DATE
  assignment_end_date DATE
}

Table VehicleRoute {
  vehicle_id INTEGER [ref: > Vehicle.id]
  route_id INTEGER [ref: > Route.id]
  assignment_date DATE
  end_assignment_date DATE
}


