import csv
import random
from secrets import choice
import string
import psycopg2


from faker import Faker
from faker_vehicle import VehicleProvider


fake = Faker("uk_UA")
fake.add_provider(VehicleProvider)


def fetch_violation_times():
    """
    Fetches violation data from the database:
    - time_of_violation for each violation_id
    - violation_ids that already have protocols
    Returns two dictionaries:
    - violation_times: {violation_id: time_of_violation}
    - protocol_violation_ids: Set of violation_ids with protocols
    """
    violation_times = {}
    protocol_violation_ids = set()
    conn = None
    cursor = None

    try:
        conn = psycopg2.connect(
            "postgresql://postgres:password@localhost:5432/course_work"
        )
        cursor = conn.cursor()

        # Fetch violation times
        cursor.execute("SELECT id, time_of_violation FROM violations;")
        for row in cursor.fetchall():
            violation_id, time_of_violation = row
            violation_times[violation_id] = time_of_violation

        # Fetch violation_ids that already have protocols
        cursor.execute("SELECT violation_id FROM accident_protocols;")
        protocol_violation_ids = {row[0] for row in cursor.fetchall()}

    except Exception as e:
        print(f"Error fetching violation data: {e}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

    return violation_times, protocol_violation_ids


# Генерація даних для таблиці citizens
def generate_citizens(filename, count):
    citizens = []
    for _ in range(count):
        date_of_birth = fake.date_of_birth(minimum_age=1, maximum_age=100)
        gender = random.choice(["male", "female"])

        citizen = {
            "id": None,  # Primary key auto-incremented
            "first_name": (
                fake.first_name_male() if gender == "male" else fake.first_name_female()
            ),
            "last_name": (
                fake.last_name() if gender == "male" else fake.last_name_female()
            ),
            "patronymic": (
                fake.middle_name() if gender == "male" else fake.middle_name_female()
            ),
            "date_of_birth": date_of_birth.strftime("%Y-%m-%d"),
        }

        print(f"adding {citizen}")

        citizens.append(citizen)

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=citizens[0].keys())
        writer.writeheader()
        writer.writerows(citizens)


# Генерація даних для таблиці drivers
def generate_drivers(filename, citizens_count, count):
    drivers = []
    used_citizen_ids = set()
    for _ in range(count):
        citizen_id = random.randint(1, citizens_count)
        while citizen_id in used_citizen_ids:
            citizen_id = random.randint(1, citizens_count)
        used_citizen_ids.add(citizen_id)

        license_number = fake.bothify("???######", letters="ABCEHIKMOPTX")
        license_issued_time = fake.date_time_this_century(
            before_now=True, after_now=False
        )

        driver = {
            "id": None,  # Primary key auto-incremented
            "citizen_id": citizen_id,
            "license_number": license_number,
            "license_issued_time": license_issued_time.strftime("%Y-%m-%d %H:%M:%S"),
        }

        print(f"adding {driver}")

        drivers.append(driver)

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=drivers[0].keys())
        writer.writeheader()
        writer.writerows(drivers)


def generate_police_officers(filename, citizens_count, count):
    police_officers = []
    citizen_ids = random.sample(range(1, citizens_count + 1), count)

    # Define ranks and their weights
    ranks = [
        "junior_sergeant",
        "sergeant",
        "senior_sergeant",
        "junior_lieutenant",
        "lieutenant",
        "senior_lieutenant",
        "captain",
        "major",
        "lieutenant_colonel",
        "colonel",
    ]
    weights = [0.1, 0.2, 0.2, 0.1, 0.1, 0.1, 0.1, 0.05, 0.03, 0.02]

    for citizen_id in citizen_ids:
        badge_number = fake.bothify("???######", letters="ABCEHIKMOPTX")
        rank = random.choices(ranks, weights=weights, k=1)[
            0
        ]  # Choose a rank with weights

        police_officer = {
            "id": None,  # Primary key auto-incremented
            "citizen_id": citizen_id,
            "badge_number": badge_number,
            "rank": rank,  # Use just the rank without weights
        }

        print(f"adding {police_officer}")

        police_officers.append(police_officer)

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=police_officers[0].keys())
        writer.writeheader()
        writer.writerows(police_officers)


# Генерація даних для таблиці vehicles
def generate_vehicles(filename, citizens_count, vehicle_types_count, count):
    vehicles = []
    for _ in range(count):
        owner_id = random.randint(1, citizens_count)
        vehicle_type_id = random.randint(1, vehicle_types_count)

        choice = fake.random_element(
            [
                ("standart", 0.9),
                ("custom", 0.1),
            ]
        )

        if choice == "standart":
            registration_number = fake.bothify("??####??", letters="ABCEHIKMOPTX")
        else:
            length = random.randint(3, 8)
            registration_number = "".join(
                random.choices(string.ascii_uppercase + string.digits, k=length)
            )

        vin = fake.vin()
        engine_type = random.choice(["gasoline", "diesel", "electric", "hybrid"])
        engine_capacity = (
            None if engine_type == "electric" else round(random.uniform(1.0, 5.0), 2)
        )
        # Determine seating capacity based on vehicle type
        if vehicle_type_id in [1, 9]:  # Car or Electric Car
            seating_capacity = random.randint(2, 8)
        elif vehicle_type_id == 2:  # Motorcycle
            seating_capacity = random.randint(1, 2)
        elif vehicle_type_id == 4:  # Bus
            seating_capacity = random.randint(9, 50)  # Assuming max 50 for buses
        elif vehicle_type_id == 3:  # Truck
            seating_capacity = 2
        elif vehicle_type_id == 7:  # Trailer
            seating_capacity = None
        elif vehicle_type_id == 6:  # Special Purpose Vehicle
            seating_capacity = random.randint(1, 10)
        elif vehicle_type_id == 11:  # Dump Truck
            seating_capacity = 2
        elif vehicle_type_id == 8:  # Agricultural Vehicle
            seating_capacity = random.randint(1, 3)
        elif vehicle_type_id == 10:  # ATV
            seating_capacity = random.randint(1, 2)
        elif vehicle_type_id == 5:  # Electric Scooter
            seating_capacity = 1
        else:
            seating_capacity = random.randint(1, 8)  # Default case

        vehicle_object = fake.vehicle_object()

        vehicle = {
            "id": None,  # Primary key auto-incremented
            "owner_id": owner_id,
            "vehicle_type_id": vehicle_type_id,
            "registration_number": registration_number,
            "vin": vin,
            "insurance_policy_number": fake.bothify(
                "???######", letters="ABCEHIKMOPTX"
            ),
            "model": vehicle_object["Model"],
            "brand": vehicle_object["Make"],
            "color": fake.color_name(),
            "engine_type": engine_type,
            "engine_capacity": engine_capacity,
            "seating_capacity": seating_capacity,
            "year_of_manufacture": vehicle_object["Year"],
        }

        print(f"adding {vehicle}")

        vehicles.append(vehicle)

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=vehicles[0].keys())
        writer.writeheader()
        writer.writerows(vehicles)


# Генерація даних для таблиці violations


def generate_locations(filename, count):
    locations = []

    # Define bounding box for Ukraine
    min_lat, max_lat = 44.0, 52.5
    min_lon, max_lon = 22.0, 40.5

    for _ in range(count):
        location = {
            "id": None,  # Primary key auto-incremented
            "latitude": round(random.uniform(min_lat, max_lat), 6),
            "longitude": round(random.uniform(min_lon, max_lon), 6),
            "street": fake.street_name(),  # Generates a Ukrainian street name
            "building_number": fake.building_number(),
            "description": (
                fake.text(max_nb_chars=200) if random.random() < 0.2 else None
            ),
        }

        print(f"adding {location}")

        locations.append(location)

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=locations[0].keys())
        writer.writeheader()
        writer.writerows(locations)


def generate_violations(filename, vehicles_count, locations_count, count):
    traffic_rules_count = 291
    administrative_offenses_count = 54

    violations = []

    for _ in range(count):
        vehicle_id = random.randint(1, vehicles_count)
        location_id = random.randint(1, locations_count)
        administrative_offense_id = random.randint(1, administrative_offenses_count)
        traffic_rule_id = random.randint(1, traffic_rules_count)
        time_of_violation = fake.date_time_between(start_date="-10y", end_date="now")

        violation = {
            "id": None,  # Primary key auto-incremented
            "time_of_violation": time_of_violation.strftime("%Y-%m-%d %H:%M:%S"),
            "description": (
                fake.text(max_nb_chars=200) if random.random() < 0.7 else None
            ),
            "vehicle_id": vehicle_id,
            "location_id": location_id,
            "administrative_offense_id": administrative_offense_id,
            "traffic_rule_id": traffic_rule_id,
        }

        print(f"adding {violation}")

        violations.append(violation)

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=violations[0].keys())
        writer.writeheader()
        writer.writerows(violations)


def generate_evidences(filename, violations_count):
    evidences = []

    for violation_id in range(1, violations_count + 1):
        num_evidences = random.choices(
            range(11), weights=[1, 2, 3, 4, 5, 4, 3, 2, 1, 1, 1], k=1
        )[0]

        for _ in range(num_evidences):
            evidence = {
                "id": None,  # Primary key auto-incremented
                "violation_id": violation_id,
                "type": random.choice(["photo", "video"]),
                "url": fake.image_url(),
            }

            print(f"adding {evidence}")

            evidences.append(evidence)

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=evidences[0].keys())
        writer.writeheader()
        writer.writerows(evidences)


def generate_accident_protocols(
    filename,
    violations_count,
    police_officers_count,
    citizens_count,
    count,
):
    protocols = []

    # Fetch violation times from the database
    violation_times = fetch_violation_times()

    for _ in range(count):
        # Randomly pick a violation ID
        violation_id = random.randint(1, violations_count)

        # Get the corresponding time_of_violation
        time_of_violation = violation_times.get(violation_id)

        if not time_of_violation:
            print(
                f"Skipping violation ID {violation_id} as it has no time_of_violation."
            )
            continue

        # Ensure time_of_drawing_up is after time_of_violation
        time_of_drawing_up = fake.date_time_between(
            start_date=time_of_violation, end_date="now"
        ).strftime("%Y-%m-%d %H:%M:%S")

        protocol = {
            "id": None,  # Primary key auto-incremented
            "series": fake.lexify(
                text="??", letters="ABCEHIKMOPTX"
            ),  # Random 2-letter series
            "number": fake.numerify(text="######"),  # Random 6-digit number
            "defendant_explanation": (
                fake.text(max_nb_chars=300) if random.random() < 0.5 else None
            ),
            "time_of_drawing_up": time_of_drawing_up,
            "violation_id": violation_id,
            "police_officer_id": random.randint(1, police_officers_count),
            "defendant_id": random.randint(1, citizens_count),
        }

        print(f"adding {protocol}")

        protocols.append(protocol)

    # Write protocols to a CSV file
    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=protocols[0].keys())
        writer.writeheader()
        writer.writerows(protocols)


def generate_citizens_on_protocol(filename, citizens_count, protocols_count):
    roles = ["witness", "victim"]  # Example roles

    citizens_protocols = []

    for _ in range(protocols_count):

        num_of_citizens_on_protocol = random.choices(
            range(4), weights=[3, 4, 2, 1], k=1
        )[0]

        for _ in range(num_of_citizens_on_protocol):

            citizen_on_protocol = {
                "id": None,  # Primary key auto-incremented
                "role": random.choice(roles),
                "citizen_id": random.randint(1, citizens_count),
                "protocol_id": random.randint(1, protocols_count),
                "testimony": (
                    fake.text(max_nb_chars=300) if random.random() < 0.7 else None
                ),
            }

            print(f"adding {citizen_on_protocol}")

            citizens_protocols.append(citizen_on_protocol)

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=citizens_protocols[0].keys())
        writer.writeheader()
        writer.writerows(citizens_protocols)


def generate_accident_resolutions(
    filename, violations_count, police_officers_count, locations_count, count
):
    resolutions = []

    # Fetch violation data
    violation_times, protocol_violation_ids = fetch_violation_times()

    for _ in range(count):
        # Randomly pick a violation_id
        violation_id = random.randint(1, violations_count)

        # Skip if this violation already has a protocol
        if violation_id in protocol_violation_ids:
            print(f"Skipping violation ID {violation_id} (already has a protocol)")
            continue

        # Get the corresponding time_of_violation
        time_of_violation = violation_times.get(violation_id)

        if not time_of_violation:
            print(f"Skipping violation ID {violation_id} (no time_of_violation found)")
            continue

        # Ensure time_of_consideration is after time_of_violation
        time_of_consideration = fake.date_time_between(
            start_date=time_of_violation, end_date="now"
        )

        # Generate time_of_entry_into_force after time_of_consideration
        time_of_entry_into_force = fake.date_time_between(
            start_date=time_of_consideration, end_date="+30d"
        )

        resolution = {
            "id": None,  # Primary key auto-incremented
            "series": fake.lexify("??", letters="ABCEHIKMOPTX"),
            "number": fake.numerify("######"),
            "time_of_consideration": time_of_consideration.strftime(
                "%Y-%m-%d %H:%M:%S"
            ),
            "time_of_entry_into_force": time_of_entry_into_force.strftime(
                "%Y-%m-%d %H:%M:%S"
            ),
            "violation_id": violation_id,
            "police_officer_id": random.randint(1, police_officers_count),
            "location_id": random.randint(1, locations_count),
        }

        print(f"adding {resolution}")

        resolutions.append(resolution)

    # Write resolutions to a CSV file
    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=resolutions[0].keys())
        writer.writeheader()
        writer.writerows(resolutions)


# Виклик функцій для генерації даних
if __name__ == "__main__":
    citizens_count = 10000
    drivers_count = 9000
    police_officer_count = 1000
    vehicles_count = 15000
    location_count = 5000
    violations_count = 20000
    protocols_count = 9000
    resolutions_count = 9000

    # generate_citizens("../csv/citizens.csv", citizens_count)
    # generate_drivers("../csv/drivers.csv", citizens_count, drivers_count)
    # generate_police_officers(
    #     "../csv/police_officers.csv", citizens_count, police_officer_count
    # )
    # generate_vehicles("../csv/vehicles.csv", citizens_count, 11, vehicles_count)
    # generate_locations("../csv/locations.csv", location_count)

    # generate_violations(
    #     "../csv/violations.csv", vehicles_count, location_count, violations_count
    # )

    # generate_evidences("../csv/evidences.csv", violations_count)
    # generate_accident_protocols(
    #     "../csv/accident_protocols.csv",
    #     violations_count,
    #     police_officer_count,
    #     citizens_count,
    #     protocols_count,
    # )

    # generate_citizens_on_protocol(
    #     "../csv/citizens_on_protocol.csv",
    #     citizens_count,
    #     protocols_count=protocols_count,
    # )

    generate_accident_resolutions(
        "../csv/accident_resolutions.csv",
        violations_count,
        police_officer_count,
        location_count,
        count=resolutions_count,
    )
