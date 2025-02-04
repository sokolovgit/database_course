CREATE TABLE "citizens"(
    "id" BIGINT NOT NULL,
    "first_name" VARCHAR(255) NOT NULL,
    "last_name" VARCHAR(255) NOT NULL,
    "patronymic" VARCHAR(255) NULL,
    "date_of_birth" BIGINT NOT NULL,
    "location_of_birth_id" BIGINT NOT NULL
);

ALTER TABLE
    "citizens"
ADD
    PRIMARY KEY("id");

CREATE TABLE "drivers"(
    "id" BIGINT NOT NULL,
    "citizen_id" BIGINT NOT NULL,
    "license_number" BIGINT NOT NULL
);

ALTER TABLE
    "drivers"
ADD
    PRIMARY KEY("id");

ALTER TABLE
    "drivers"
ADD
    CONSTRAINT "drivers_license_number_unique" UNIQUE("license_number");

CREATE TABLE "police_officer"(
    "id" BIGINT NOT NULL,
    "citizen_id" BIGINT NOT NULL,
    "rank" VARCHAR(255) NOT NULL,
    "badge_number" VARCHAR(255) NOT NULL
);

ALTER TABLE
    "police_officer"
ADD
    PRIMARY KEY("id");

ALTER TABLE
    "police_officer"
ADD
    CONSTRAINT "police_officer_badge_number_unique" UNIQUE("badge_number");

CREATE TABLE "vehicles"(
    "id" BIGINT NOT NULL,
    "owner_id" BIGINT NOT NULL,
    "registration_number" VARCHAR(255) NOT NULL,
    "model" VARCHAR(255) NOT NULL,
    "brand" VARCHAR(255) NOT NULL,
    "year_of_manufacture" INTEGER NOT NULL
);

ALTER TABLE
    "vehicles"
ADD
    PRIMARY KEY("id");

ALTER TABLE
    "vehicles"
ADD
    CONSTRAINT "vehicles_registration_number_unique" UNIQUE("registration_number");

CREATE TABLE "violations"(
    "id" BIGINT NOT NULL,
    "date" DATE NOT NULL,
    "time" TIME(0) WITHOUT TIME ZONE NOT NULL,
    "description" TEXT NOT NULL,
    "traffic_rule_id" BIGINT NOT NULL,
    "location_id" BIGINT NOT NULL,
    "vehicle_id" BIGINT NOT NULL
);

ALTER TABLE
    "violations"
ADD
    PRIMARY KEY("id");

CREATE TABLE "traffic_rules"(
    "id" BIGINT NOT NULL,
    "article" INTEGER NOT NULL,
    "part" INTEGER NOT NULL
);

ALTER TABLE
    "traffic_rules"
ADD
    PRIMARY KEY("id");

CREATE TABLE "evidences"(
    "id" BIGINT NOT NULL,
    "type" VARCHAR(255) CHECK ("type" IN('photo', 'video')) NOT NULL,
    "url" VARCHAR(255) NOT NULL,
    "violation_id" BIGINT NOT NULL
);

ALTER TABLE
    "evidences"
ADD
    PRIMARY KEY("id");

CREATE TABLE "locations"(
    "id" BIGINT NOT NULL,
    "longitude" DECIMAL(8, 2) NOT NULL,
    "latitude" DECIMAL(8, 2) NOT NULL,
    "street" VARCHAR(255) NULL,
    "building_number" BIGINT NULL,
    "description" BIGINT NULL
);

ALTER TABLE
    "locations"
ADD
    PRIMARY KEY("id");

CREATE TABLE "accident_protocols"(
    "id" BIGINT NOT NULL,
    "series" CHAR(2) NOT NULL,
    "number" BIGINT NOT NULL,
    "citizen_explanation" TEXT NOT NULL,
    "time" TIMESTAMP(0) WITH TIME zone NOT NULL,
    "police_officer_id" BIGINT NOT NULL,
    "citizen_id" BIGINT NOT NULL,
    "vehicle_id" BIGINT NOT NULL,
    "violation_id" BIGINT NOT NULL,
    "location_id" BIGINT NOT NULL,
    "administrative_offense_id" BIGINT NOT NULL
);

ALTER TABLE
    "accident_protocols"
ADD
    PRIMARY KEY("id");

CREATE TABLE "accident_resolutions"(
    "id" BIGINT NOT NULL,
    "series" CHAR(2) NOT NULL,
    "number" BIGINT NOT NULL,
    "penalty_fee" BIGINT NOT NULL,
    "date_of_consideration" DATE NOT NULL,
    "date_of_entry_into_force" DATE NOT NULL,
    "police_officer_id" BIGINT NOT NULL,
    "vehicle_id" BIGINT NOT NULL,
    "location_id" BIGINT NOT NULL,
    "violation_id" BIGINT NOT NULL,
    "administrative_offense_id" BIGINT NOT NULL
);

ALTER TABLE
    "accident_resolutions"
ADD
    PRIMARY KEY("id");

CREATE TABLE "administrative_offenses"(
    "id" BIGINT NOT NULL,
    "article" INTEGER NOT NULL,
    "sup" INTEGER NOT NULL,
    "part" INTEGER NOT NULL
);

ALTER TABLE
    "administrative_offenses"
ADD
    PRIMARY KEY("id");

CREATE TABLE "witnesses_on_protocol"(
    "id" BIGINT NOT NULL,
    "citizen_id" BIGINT NOT NULL,
    "accident_protocol_id" BIGINT NOT NULL
);

ALTER TABLE
    "witnesses_on_protocol"
ADD
    PRIMARY KEY("id");

CREATE TABLE "victims_on_protocol"(
    "id" BIGINT NOT NULL,
    "citizen_id" BIGINT NOT NULL,
    "accident_protocol_id" BIGINT NOT NULL
);

ALTER TABLE
    "victims_on_protocol"
ADD
    PRIMARY KEY("id");

ALTER TABLE
    "accident_protocols"
ADD
    CONSTRAINT "accident_protocols_administrative_offense_id_foreign" FOREIGN KEY("administrative_offense_id") REFERENCES "administrative_offenses"("id");

ALTER TABLE
    "drivers"
ADD
    CONSTRAINT "drivers_citizen_id_foreign" FOREIGN KEY("citizen_id") REFERENCES "citizens"("id");

ALTER TABLE
    "accident_resolutions"
ADD
    CONSTRAINT "accident_resolutions_police_officer_id_foreign" FOREIGN KEY("police_officer_id") REFERENCES "police_officer"("id");

ALTER TABLE
    "accident_protocols"
ADD
    CONSTRAINT "accident_protocols_violation_id_foreign" FOREIGN KEY("violation_id") REFERENCES "violations"("id");

ALTER TABLE
    "accident_protocols"
ADD
    CONSTRAINT "accident_protocols_vehicle_id_foreign" FOREIGN KEY("vehicle_id") REFERENCES "vehicles"("id");

ALTER TABLE
    "accident_resolutions"
ADD
    CONSTRAINT "accident_resolutions_vehicle_id_foreign" FOREIGN KEY("vehicle_id") REFERENCES "vehicles"("id");

ALTER TABLE
    "accident_protocols"
ADD
    CONSTRAINT "accident_protocols_citizen_id_foreign" FOREIGN KEY("citizen_id") REFERENCES "citizens"("id");

ALTER TABLE
    "accident_resolutions"
ADD
    CONSTRAINT "accident_resolutions_location_id_foreign" FOREIGN KEY("location_id") REFERENCES "locations"("id");

ALTER TABLE
    "violations"
ADD
    CONSTRAINT "violations_traffic_rule_id_foreign" FOREIGN KEY("traffic_rule_id") REFERENCES "traffic_rules"("id");

ALTER TABLE
    "accident_protocols"
ADD
    CONSTRAINT "accident_protocols_location_id_foreign" FOREIGN KEY("location_id") REFERENCES "locations"("id");

ALTER TABLE
    "witnesses_on_protocol"
ADD
    CONSTRAINT "witnesses_on_protocol_accident_protocol_id_foreign" FOREIGN KEY("accident_protocol_id") REFERENCES "accident_protocols"("id");

ALTER TABLE
    "victims_on_protocol"
ADD
    CONSTRAINT "victims_on_protocol_citizen_id_foreign" FOREIGN KEY("citizen_id") REFERENCES "citizens"("id");

ALTER TABLE
    "vehicles"
ADD
    CONSTRAINT "vehicles_owner_id_foreign" FOREIGN KEY("owner_id") REFERENCES "citizens"("id");

ALTER TABLE
    "citizens"
ADD
    CONSTRAINT "citizens_location_of_birth_id_foreign" FOREIGN KEY("location_of_birth_id") REFERENCES "locations"("id");

ALTER TABLE
    "witnesses_on_protocol"
ADD
    CONSTRAINT "witnesses_on_protocol_citizen_id_foreign" FOREIGN KEY("citizen_id") REFERENCES "citizens"("id");

ALTER TABLE
    "violations"
ADD
    CONSTRAINT "violations_location_id_foreign" FOREIGN KEY("location_id") REFERENCES "locations"("id");

ALTER TABLE
    "accident_protocols"
ADD
    CONSTRAINT "accident_protocols_police_officer_id_foreign" FOREIGN KEY("police_officer_id") REFERENCES "police_officer"("id");

ALTER TABLE
    "accident_resolutions"
ADD
    CONSTRAINT "accident_resolutions_administrative_offense_id_foreign" FOREIGN KEY("administrative_offense_id") REFERENCES "administrative_offenses"("id");

ALTER TABLE
    "accident_resolutions"
ADD
    CONSTRAINT "accident_resolutions_violation_id_foreign" FOREIGN KEY("violation_id") REFERENCES "violations"("id");

ALTER TABLE
    "violations"
ADD
    CONSTRAINT "violations_vehicle_id_foreign" FOREIGN KEY("vehicle_id") REFERENCES "vehicles"("id");

ALTER TABLE
    "police_officer"
ADD
    CONSTRAINT "police_officer_citizen_id_foreign" FOREIGN KEY("citizen_id") REFERENCES "citizens"("id");

ALTER TABLE
    "victims_on_protocol"
ADD
    CONSTRAINT "victims_on_protocol_accident_protocol_id_foreign" FOREIGN KEY("accident_protocol_id") REFERENCES "accident_protocols"("id");

ALTER TABLE
    "evidences"
ADD
    CONSTRAINT "evidences_violation_id_foreign" FOREIGN KEY("violation_id") REFERENCES "violations"("id");