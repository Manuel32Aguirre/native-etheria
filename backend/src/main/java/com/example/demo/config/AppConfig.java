package com.example.demo.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.time.Duration;

@Configuration
public class AppConfig {

    @Bean
    public RestClient openAiRestClient(OpenAiProperties properties) {
        if (properties.getApiKey() == null
                || properties.getApiKey().isBlank()
                || properties.getApiKey().equals("sk-your-openai-api-key")) {
            throw new IllegalStateException(
                    "OPENAI_API_KEY is missing. Set it in backend/.env or the process environment.");
        }

        return RestClient.builder()
                .baseUrl(properties.getBaseUrl())
                .defaultHeader("Authorization", "Bearer " + properties.getApiKey())
                .build();
    }

    @Bean
    @Qualifier("localSttRestClient")
    public RestClient localSttRestClient(SttProperties sttProperties) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(5));
        // CPU transcription of a 30s answer can take a while on a small instance.
        factory.setReadTimeout(Duration.ofSeconds(120));

        return RestClient.builder()
                .baseUrl(sttProperties.getLocalBaseUrl())
                .requestFactory(factory)
                .build();
    }
}
