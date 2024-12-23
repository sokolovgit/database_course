INSERT INTO vehicle_types (NAME, DESCRIPTION, MIN_SEATING_CAPACITY, MAX_SEATING_CAPACITY, MIN_ENGINE_CAPACITY, MAX_ENGINE_CAPACITY) VALUES
('Car', 'Passenger car used for personal or commercial purposes.', 2, 8, 1.0, 6.0),
('Electric Car', 'Vehicle powered exclusively by electricity.', 2, 8, NULL, NULL),
('Hybrid Vehicle', 'Vehicle powered by a combination of internal combustion engine and electric motor.', 2, 8, 1.0, 6.0),
('Motorcycle', 'Two-wheeled motor vehicle.', 1, 2, 0.1, 2.0),
('Van', 'Larger motor vehicle designed for passenger or cargo transport.', 2, 15, 2.0, 6.0),
('Truck', 'Motor vehicle designed to transport goods or materials.', 2, 2, 2.0, 15.0),
('Bus', 'Motor vehicle designed to carry multiple passengers.', 9, NULL, 4.0, 15.0),
('Special Purpose Vehicle', 'Vehicles such as fire trucks, ambulances, or police cars.', 1, 10, 2.0, 10.0),
('Trailer', 'Unpowered vehicle towed by another vehicle.', NULL, NULL, NULL, NULL),
('Agricultural Vehicle', 'Vehicles such as tractors used for farming purposes.', 1, 3, 1.0, 5.0),
('ATV', 'All-terrain vehicle used for off-road travel.', 1, 2, 0.5, 1.5),
('Dump Truck', 'Truck designed to transport and unload materials.', 2, 2, 2.0, 15.0);