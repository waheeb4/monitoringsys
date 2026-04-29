package com.dxc.monitoring.repository;

import com.dxc.monitoring.model.SensorReading;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SensorReadingRepository extends JpaRepository<SensorReading, Integer> {
    List<SensorReading> findByDeviceId(Integer deviceId);
}
