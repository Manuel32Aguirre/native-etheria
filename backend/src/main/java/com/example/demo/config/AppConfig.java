package com.example.demo.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class AppConfig {

    @Bean
    public RestClient openAiRestClient(OpenAiProperties properties) {
        if (properties.getApiKey() == null
                || properties.getApiKey().isBlank()
                || properties.getApiKey().equals("sk-your-openai-api-key")) {
            throw new IllegalStateException(
                    "OPENAI_API_KEY is missing. Set it in backend/native/.env or the process environment.");
        }

        return RestClient.builder()
                .baseUrl(properties.getBaseUrl())
                .defaultHeader("Authorization", "Bearer " + properties.getApiKey())
                .build();
    }
}
