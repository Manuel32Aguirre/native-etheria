package com.example.demo.client;

import com.example.demo.config.SttProperties;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Component;
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

        MultipartBodyBuilder builder = new MultipartBodyBuilder();
        builder.part("file", new ByteArrayResource(audioBytes) {
                    @Override
                    public String getFilename() {
                        return safeName;
                    }
                })
                .filename(safeName)
                .contentType(MediaType.APPLICATION_OCTET_STREAM);
        builder.part("language", properties.getLanguage());

        String responseBody;
        try {
            responseBody = restClient.post()
                    .uri("/transcribe")
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(builder.build())
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
