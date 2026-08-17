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

    private static final String ENGLISH_PROMPT =
            "This is clear spoken English for language-learning practice. "
                    + "Prefer standard American English spelling and wording.";

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
        return transcribeAudio(audioBytes, filename, null);
    }

    /**
     * @param vocabularyHint optional words/phrases that may appear (helps uncommon terms).
     *                       Do not pass the full expected answer alone — Whisper can over-bias.
     */
    public String transcribeAudio(byte[] audioBytes, String filename, String vocabularyHint) {
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
        // Force English decoding — never auto-detect Spanish.
        form.add("language", "en");
        form.add("response_format", "json");
        form.add("temperature", "0");

        String prompt = ENGLISH_PROMPT;
        if (vocabularyHint != null && !vocabularyHint.isBlank()) {
            prompt = ENGLISH_PROMPT + " Possible terms: " + vocabularyHint;
        }
        form.add("prompt", prompt);

        log.info("GROQ STT model={} language=en", properties.getGroqModel());

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
