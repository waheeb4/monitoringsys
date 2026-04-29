package com.dxc.monitoring.controller;

import com.dxc.monitoring.model.SensorReading;
import com.dxc.monitoring.repository.SensorReadingRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/readings")
public class SensorReadingController {

    private final SensorReadingRepository readingRepository;

    public SensorReadingController(SensorReadingRepository readingRepository) {
        this.readingRepository = readingRepository;
    }

    @GetMapping
    public List<SensorReading> getAll() {
        return readingRepository.findAll();
    }

    @GetMapping("/device/{deviceId}")
    public List<SensorReading> getByDevice(@PathVariable Integer deviceId) {
        return readingRepository.findByDeviceId(deviceId);
    }

    @PostMapping
    public SensorReading create(@RequestBody SensorReading reading) {
        return readingRepository.save(reading);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        if (!readingRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        readingRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
