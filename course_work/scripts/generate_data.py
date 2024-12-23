from calendar import c
import csv
from itertools import count
import random
from secrets import choice
import string
import psycopg2


from faker import Faker
from faker_vehicle import VehicleProvider


fake = Faker("uk_UA")
fake.add_provider(VehicleProvider)

regions = [
    {"name": "AR Krym", "codes": ["AK", "KK", "TK"]},
    {"name": "Vinnytska oblast", "codes": ["AB", "KB", "IM"]},
    {"name": "Volynska oblast", "codes": ["AC", "KC", "CM"]},
    {"name": "Dnipropetrovska oblast", "codes": ["AE", "KE", "PP"]},
    {"name": "Donetska oblast", "codes": ["AH", "KH", "TH"]},
    {"name": "Zhytomyrska oblast", "codes": ["AM", "KM", "TM"]},
    {"name": "Zakarpatska oblast", "codes": ["AO", "KO", "MT"]},
    {"name": "Zaporizka oblast", "codes": ["AP", "KP", "TP"]},
    {"name": "Ivano-Frankivska oblast", "codes": ["AT", "KT", "TO"]},
    {"name": "Kyivska oblast", "codes": ["AI", "KI", "TI"]},
    {"name": "misto Kyiv", "codes": ["AA", "KA", "TT"]},
    {"name": "Kirovohradska oblast", "codes": ["BA", "HA", "XA"]},
    {"name": "Luhanska oblast", "codes": ["BB", "HB", "EP"]},
    {"name": "Lvivska oblast", "codes": ["BC", "HC", "CC"]},
    {"name": "Mykolaivska oblast", "codes": ["BE", "HE", "XE"]},
    {"name": "Odeska oblast", "codes": ["BH", "HH", "OO"]},
    {"name": "Poltavska oblast", "codes": ["BI", "HI", "XI"]},
    {"name": "Rivnenska oblast", "codes": ["BK", "HK", "XK"]},
    {"name": "Sumska oblast", "codes": ["BM", "HM", "XM"]},
    {"name": "Ternopilska oblast", "codes": ["BO", "HO", "XO"]},
    {"name": "Kharkivska oblast", "codes": ["AX", "KX", "XX"]},
    {"name": "Khersonska oblast", "codes": ["BT", "HT", "XT"]},
    {"name": "Khmelnytska oblast", "codes": ["BX", "HX", "OX"]},
    {"name": "Cherkaska oblast", "codes": ["CA", "IA", "OA"]},
    {"name": "Chernihivska oblast", "codes": ["CB", "IB", "OB"]},
    {"name": "Chernivetska oblast", "codes": ["CE", "IE", "OE"]},
    {"name": "misto Sevastopol", "codes": ["CH", "IH", "OH"]},
]


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
            "postgresql://postgres:tec928100@localhost:5432/course_work"
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
    for i in range(count):
        date_of_birth = fake.date_of_birth(minimum_age=1, maximum_age=100)
        gender = random.choice(["male", "female"])

        citizen = {
            "id": i + 1,  # Primary key auto-incremented
            "first_name": (
                fake.first_name_male() if gender == "male" else fake.first_name_female()
            ),
            "last_name": (
                fake.last_name_male() if gender == "male" else fake.last_name_female()
            ),
            "patronymic": (
                fake.middle_name_male()
                if gender == "male"
                else fake.middle_name_female()
            ),
            "date_of_birth": date_of_birth.strftime("%Y-%m-%d"),
        }

        print(f"{i} adding {citizen}")

        citizens.append(citizen)

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=citizens[0].keys())
        writer.writeheader()
        writer.writerows(citizens)


# Генерація даних для таблиці drivers
def generate_drivers(filename, citizens_count, count):
    drivers = []
    used_citizen_ids = set()
    for i in range(count):
        citizen_id = random.randint(1, citizens_count)
        while citizen_id in used_citizen_ids:
            citizen_id = random.randint(1, citizens_count)
        used_citizen_ids.add(citizen_id)

        license_number = fake.bothify("???######", letters="ABCEHIKMOPTX")
        license_issued_time = fake.date_time_this_century(
            before_now=True, after_now=False
        )

        driver = {
            "id": i + 1,  # Primary key auto-incremented
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
    counter = 0

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
        counter += 1
        police_officer = {
            "id": counter,  # Primary key auto-incremented
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
def generate_vehicles(filename, citizens_count, count):
    vehicles = []
    vehicle_type_data = {
        1: {
            "min_seating": 2,
            "max_seating": 8,
            "min_engine": 1.00,
            "max_engine": 6.00,
        },  # Car
        2: {
            "min_seating": 2,
            "max_seating": 8,
            "min_engine": None,
            "max_engine": None,
        },  # Electric Car
        3: {
            "min_seating": 2,
            "max_seating": 8,
            "min_engine": 1.00,
            "max_engine": 6.00,
        },  # Hybrid Vehicle
        4: {
            "min_seating": 1,
            "max_seating": 2,
            "min_engine": 0.10,
            "max_engine": 2.00,
        },  # Motorcycle
        5: {
            "min_seating": 2,
            "max_seating": 15,
            "min_engine": 2.00,
            "max_engine": 6.00,
        },  # Van
        6: {
            "min_seating": 2,
            "max_seating": 2,
            "min_engine": 2.00,
            "max_engine": 15.00,
        },  # Truck
        7: {
            "min_seating": 9,
            "max_seating": None,
            "min_engine": 4.00,
            "max_engine": 15.00,
        },  # Bus
        8: {
            "min_seating": 1,
            "max_seating": 10,
            "min_engine": 2.00,
            "max_engine": 10.00,
        },  # Special Purpose Vehicle
        9: {
            "min_seating": None,
            "max_seating": None,
            "min_engine": None,
            "max_engine": None,
        },  # Trailer
        10: {
            "min_seating": 1,
            "max_seating": 3,
            "min_engine": 1.00,
            "max_engine": 5.00,
        },  # Agricultural Vehicle
        11: {
            "min_seating": 1,
            "max_seating": 2,
            "min_engine": 0.50,
            "max_engine": 1.50,
        },  # ATV
        12: {
            "min_seating": 2,
            "max_seating": 2,
            "min_engine": 2.00,
            "max_engine": 15.00,
        },  # Dump Truck
    }

    for i in range(count):
        owner_id = random.randint(1, citizens_count)
        vehicle_type_id = random.randint(
            1, len(vehicle_type_data)
        )  # Get vehicle type ID from the data

        choice = random.choices(["standard", "custom"], weights=[9, 1])[0]

        if choice == "standard":
            region = random.choice(regions)
            region_code = random.choice(region["codes"])
            registration_number = fake.bothify(
                f"{region_code}####??", letters="ABCEHIKMOPTX"
            )
        else:
            length = random.randint(3, 8)
            registration_number = "".join(
                random.choices(string.ascii_uppercase + string.digits, k=length)
            )
            registration_number = "".join(
                random.sample(registration_number, len(registration_number))
            )

        vin = fake.vin()
        type_data = vehicle_type_data.get(vehicle_type_id, {})
        engine_capacity = (
            round(random.uniform(type_data["min_engine"], type_data["max_engine"]), 2)
            if type_data.get("min_engine") and type_data.get("max_engine")
            else None
        )
        seating_capacity = (
            random.randint(type_data["min_seating"], type_data["max_seating"])
            if type_data.get("min_seating") and type_data.get("max_seating")
            else None
        )

        vehicle_object = fake.vehicle_object()

        vehicle = {
            "id": i + 1,
            "owner_id": owner_id,
            "vehicle_type_id": vehicle_type_id,
            "registration_number": registration_number,
            "vin": vin,
            "insurance_policy_number": (
                fake.bothify("???######", letters="ABCEHIKMOPTX")
                if random.random() < 0.9
                else None
            ),
            "model": vehicle_object["Model"],
            "brand": vehicle_object["Make"],
            "color": fake.color_name(),
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

    for i in range(count):
        location = {
            "id": i + 1,  # Primary key auto-incremented
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

    for i in range(count):
        vehicle_id = random.randint(1, vehicles_count)
        location_id = random.randint(1, locations_count)
        administrative_offense_id = random.randint(1, administrative_offenses_count)
        traffic_rule_id = random.randint(1, traffic_rules_count)
        time_of_violation = fake.date_time_between(start_date="-10y", end_date="now")

        violation = {
            "id": i + 1,  # Primary key auto-incremented
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

    counter = 0
    for violation_id in range(1, violations_count + 1):
        num_evidences = random.choices(
            range(11), weights=[1, 2, 3, 4, 5, 4, 3, 2, 1, 1, 1], k=1
        )[0]

        for _ in range(num_evidences):
            counter += 1

            evidence = {
                "id": counter,  # Primary key auto-incremented
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
    counter = 0

    # Fetch violation times from the database
    violation_times, protocol_violation_ids = fetch_violation_times()

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

        # Ensure police officer is not the same as the defendant
        police_officer_id = random.randint(1, police_officers_count)
        defendant_id = random.randint(1, citizens_count)

        # If the selected police officer is the same as the defendant, change the police officer ID
        while police_officer_id == defendant_id:
            police_officer_id = random.randint(1, police_officers_count)

        counter += 1

        protocol = {
            "id": counter,  # Primary key auto-incremented
            "series": fake.lexify(
                text="??", letters="ABCEHIKMOPTX"
            ),  # Random 2-letter series
            "number": fake.numerify(text="######"),  # Random 6-digit number
            "defendant_explanation": (
                fake.text(max_nb_chars=300) if random.random() < 0.5 else None
            ),
            "time_of_drawing_up": time_of_drawing_up,
            "violation_id": violation_id,
            "police_officer_id": police_officer_id,
            "defendant_id": defendant_id,
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
    counter = 0

    for _ in range(protocols_count):

        num_of_citizens_on_protocol = random.choices(
            range(4), weights=[3, 4, 2, 1], k=1
        )[0]

        for _ in range(num_of_citizens_on_protocol):
            counter += 1

            citizen_on_protocol = {
                "id": counter,  # Primary key auto-incremented
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
    counter = 0
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

        counter += 1

        resolution = {
            "id": counter,  # Primary key auto-incremented
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
    citizens_count = 20000
    drivers_count = 10000
    police_officer_count = 2000
    vehicles_count = 15000
    location_count = 5000
    violations_count = 30000
    protocols_count = 14000
    resolutions_count = 14000

    # generate_drivers("../csv/drivers.csv", citizens_count, drivers_count)
    # generate_citizens("../csv/citizens.csv", citizens_count)
    # generate_police_officers(
    #     "../csv/police_officers.csv", citizens_count, police_officer_count
    # )
    # generate_vehicles("../csv/vehicles.csv", citizens_count, vehicles_count)
    # generate_locations("../csv/locations.csv", location_count)

    # generate_violations(
    #     "../csv/violations.csv", vehicles_count, location_count, violations_count
    # )

    # generate_evidences("../csv/evidences.csv", violations_count)
    generate_accident_protocols(
        "../csv/accident_protocols.csv",
        violations_count,
        police_officer_count,
        citizens_count,
        protocols_count,
    )

    generate_citizens_on_protocol(
        "../csv/citizens_on_protocol.csv",
        citizens_count,
        protocols_count=protocols_count,
    )

    generate_accident_resolutions(
        "../csv/accident_resolutions.csv",
        violations_count,
        police_officer_count,
        location_count,
        count=resolutions_count,
    )
