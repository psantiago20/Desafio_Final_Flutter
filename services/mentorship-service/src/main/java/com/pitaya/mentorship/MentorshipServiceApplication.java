package com.pitaya.mentorship;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients
@EnableRabbit
@EnableScheduling
@ComponentScan(
    basePackages = {"com.pitaya.mentorship", "com.pitaya.shared"},
    excludeFilters = {
        @ComponentScan.Filter(
            type = FilterType.REGEX,
            pattern = "com\\.pitaya\\.shared\\.exception\\.GlobalExceptionHandler"
        )
    }
)
public class MentorshipServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(MentorshipServiceApplication.class, args);
    }
}
