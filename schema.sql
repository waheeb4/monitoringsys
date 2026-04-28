CREATE DATABASE IF NOT EXISTS monitoring;
USE monitoring;

CREATE TABLE devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sensor_readings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    temperature FLOAT,
    humidity FLOAT,
    pressure FLOAT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id)
);

INSERT INTO devices (name, location) VALUES
    ('sensor-01', 'warehouse-a'),
    ('sensor-02', 'warehouse-b');

INSERT INTO sensor_readings (device_id, temperature, humidity, pressure) VALUES
    (1, 22.5, 60.1, 1013.2),
    (1, 23.1, 61.4, 1012.8),
    (2, 19.8, 55.0, 1014.0);
