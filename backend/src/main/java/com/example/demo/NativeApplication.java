package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

import com.example.demo.config.OpenAiProperties;
import com.example.demo.config.ReviewProperties;
import com.example.demo.config.MailProperties;

@SpringBootApplication
@EnableConfigurationProperties({OpenAiProperties.class, ReviewProperties.class, MailProperties.class})
public class NativeApplication {

	public static void main(String[] args) {
		SpringApplication.run(NativeApplication.class, args);
	}

}
