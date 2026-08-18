package com.jenkins;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthController {
    @GetMapping("/actuator/health")
    public Object getHealth(){
        return Map.of("status","UP");
    }

    @GetMapping("/api/hello")
    public Object hello(){
        return "Hello jenkins CI";
    }
}
