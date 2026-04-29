package com.dxc.monitoring.repository;

import com.dxc.monitoring.model.Device;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceRepository extends JpaRepository<Device, Integer> {
}
