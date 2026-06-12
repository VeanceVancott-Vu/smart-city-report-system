package com.smartcity.reports;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class SmartCityReportApplication {

    public static void main(String[] args) {
        SpringApplication.run(SmartCityReportApplication.class, args);
    }
}
