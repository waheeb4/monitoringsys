package com.dxc.monitoring.controller;

import com.dxc.monitoring.model.Device;
import com.dxc.monitoring.repository.DeviceRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/devices")
public class DeviceController {

    private final DeviceRepository deviceRepository;

    public DeviceController(DeviceRepository deviceRepository) {
        this.deviceRepository = deviceRepository;
    }

    @GetMapping
    public List<Device> getAll() {
        return deviceRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Device> getById(@PathVariable Integer id) {
        return deviceRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Device create(@RequestBody Device device) {
        return deviceRepository.save(device);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        if (!deviceRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        deviceRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
