package com.example.demo.client;

import com.example.demo.config.SttProperties;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

/** Calls the local faster-whisper microservice (no OpenAI cost). */
@Slf4j
@Component
public class LocalSttClient {

    private final RestClient restClient;
    private final SttProperties properties;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public LocalSttClient(
            @Qualifier("localSttRestClient") RestClient localSttRestClient,
            SttProperties properties) {
        this.restClient = localSttRestClient;
        this.properties = properties;
    }

    public String transcribeAudio(byte[] audioBytes, String filename) {
        String safeName = filename == null || filename.isBlank() ? "audio.m4a" : filename;

        ByteArrayResource resource = new ByteArrayResource(audioBytes) {
            @Override
            public String getFilename() {
                return safeName;
            }
        };

        // Same multipart style as OpenAiClient.transcribeAudio — no MultipartBodyBuilder
        // (that needs reactive-streams / WebFlux, which this app does not use).
        MultiValueMap<String, Object> form = new LinkedMultiValueMap<>();
        form.add("file", resource);
        form.add("language", properties.getLanguage());

        String responseBody;
        try {
            responseBody = restClient.post()
                    .uri("/transcribe")
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(form)
                    .retrieve()
                    .body(String.class);
        } catch (RestClientResponseException ex) {
            log.error("Local STT request failed: {} {}", ex.getStatusCode(), ex.getResponseBodyAsString());
            throw new IllegalStateException("Local STT service error: " + ex.getStatusCode(), ex);
        }

        try {
            JsonNode response = objectMapper.readTree(responseBody);
            return response.at("/text").asText();
        } catch (Exception ex) {
            throw new IllegalStateException("Local STT returned an invalid transcription response", ex);
        }
    }
}
