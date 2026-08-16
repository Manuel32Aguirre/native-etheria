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

/**
 * Groq speech-to-text (OpenAI-compatible Whisper endpoint).
 * Same model family as OpenAI Whisper, typically much cheaper and very fast.
 */
@Slf4j
@Component
public class GroqSttClient {

    private final RestClient restClient;
    private final SttProperties properties;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public GroqSttClient(
            @Qualifier("groqSttRestClient") RestClient groqSttRestClient,
            SttProperties properties) {
        this.restClient = groqSttRestClient;
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

        MultiValueMap<String, Object> form = new LinkedMultiValueMap<>();
        form.add("file", resource);
        form.add("model", properties.getGroqModel());
        form.add("language", properties.getLanguage());
        form.add("response_format", "json");
        form.add("temperature", "0");

        String responseBody;
        try {
            responseBody = restClient.post()
                    .uri("/audio/transcriptions")
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(form)
                    .retrieve()
                    .body(String.class);
        } catch (RestClientResponseException ex) {
            log.error("Groq STT failed: {} {}", ex.getStatusCode(), ex.getResponseBodyAsString());
            throw new IllegalStateException("Groq STT error: " + ex.getStatusCode(), ex);
        }

        try {
            JsonNode response = objectMapper.readTree(responseBody);
            String text = response.at("/text").asText();
            log.info("GROQ HEARD: {}", text);
            return text;
        } catch (Exception ex) {
            throw new IllegalStateException("Groq returned an invalid transcription response", ex);
        }
    }
}
