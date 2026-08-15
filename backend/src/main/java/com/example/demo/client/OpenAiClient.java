package com.example.demo.client;

import com.example.demo.config.OpenAiProperties;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Thin wrapper around the OpenAI HTTP API (chat/vision, Whisper STT, TTS). */
@Slf4j
@Component
public class OpenAiClient {

    private final RestClient restClient;
    private final OpenAiProperties properties;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public OpenAiClient(RestClient openAiRestClient, OpenAiProperties properties) {
        this.restClient = openAiRestClient;
        this.properties = properties;
    }

    /** Sends the image to GPT-4o and extracts reusable answers from corrected learner mistakes. */
    public List<String> extractSentencesFromImage(String imageBase64) {
        String prompt = "You are a precise data extraction API. "
            + "Your task is to turn corrected English mistakes from the provided language-learning screenshot into short, reusable answers for active-recall practice.\n\n"
            + "STRICT RULES:\n"
            + "1. The image contains multiple feedback blocks. Each block has an explanation paragraph, followed by a sentence next to a GREEN CHECKMARK icon.\n"
            + "2. You MUST IGNORE the explanation paragraphs completely.\n"
            + "3. You MUST ONLY extract the text located exactly next to the GREEN CHECKMARK.\n"
            + "4. Within the checkmark text, red words are crossed out and green words are corrections. "
            + "IGNORE all red crossed-out text and first reconstruct the grammatically correct meaning.\n"
            + "5. Rewrite that meaning as ONE short, natural, self-contained first-person answer that is easy to remember and say aloud. "
            + "Remove names, room-specific details, and one-off context unless they are essential to the correction. "
            + "Prefer common phrasing such as \"I got distracted when I came in.\" over a literal or awkward answer.\n"
                + "6. If a feedback block contains no actual correction or error, do not extract it. "
                + "Extract only blocks where the learner's sentence needed correction.\n"
                + "7. Independently check the English grammar of EVERY extracted sentence. If the interface marks a sentence as correct but it contains any grammar, word-choice, spelling, tense, article, preposition, or word-order error, "
                + "you MUST correct and rewrite it yourself before returning it. Never return incorrect English merely because the interface marked it correct.\n"
                + "8. Output EXACTLY a JSON array of strings, where each string is one reusable answer. "
            + "Do not include markdown, explanations, or any other text.";

        Map<String, Object> body = Map.of(
                "model", properties.getVisionModel(),
                "messages", List.of(
                    Map.of("role", "system", "content", prompt),
                        Map.of(
                                "role", "user",
                                "content", List.of(
                                        Map.of("type", "image_url", "image_url",
                                                Map.of("url", "data:image/jpeg;base64," + imageBase64))
                                )
                        )
                ),
                "temperature", 0
        );

        String content = chatCompletion(body);
        return parseJsonArrayOfStrings(content);
    }

    /** Asks the configured vision-capable model for a conversational question. */
    public String generateVariableQuestion(String originalText) {
        String prompt = "You are helping a language learner practice active recall. "
                + "Write ONE short, natural, conversational English question whose only logical answer is "
                + "exactly this sentence: \"" + originalText + "\". "
                + "Do not reveal the answer. Reply with ONLY the question text, no quotes, no explanation.";

        Map<String, Object> body = Map.of(
                "model", properties.getVisionModel(),
                "messages", List.of(
                        Map.of("role", "user", "content", prompt)
                ),
                "temperature", 0.7
        );

        return chatCompletion(body).trim();
    }

    private String chatCompletion(Map<String, Object> body) {
        String responseBody = restClient.post()
                .uri("/chat/completions")
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(String.class);

        try {
            JsonNode response = objectMapper.readTree(responseBody);
            return response.at("/choices/0/message/content").asText();
        } catch (Exception ex) {
            throw new IllegalStateException("OpenAI returned an invalid chat completion response", ex);
        }
    }

    private List<String> parseJsonArrayOfStrings(String content) {
        try {
            String cleaned = content.trim()
                    .replaceAll("^```(json)?", "")
                    .replaceAll("```$", "")
                    .trim();
            JsonNode node = objectMapper.readTree(cleaned);
            List<String> sentences = new ArrayList<>();
            node.forEach(n -> sentences.add(n.asText()));
            return sentences;
        } catch (Exception e) {
            log.warn("Could not parse OpenAI vision response as JSON array, falling back to line split", e);
            List<String> lines = new ArrayList<>();
            for (String line : content.split("\\r?\\n")) {
                String trimmed = line.replaceAll("^[\\-*\\d.\\s]+", "").trim();
                if (!trimmed.isBlank()) {
                    lines.add(trimmed);
                }
            }
            return lines;
        }
    }

    /** Transcribes audio via Whisper. Returns the raw transcript text. */
    public String transcribeAudio(byte[] audioBytes, String filename) {
        ByteArrayResource resource = new ByteArrayResource(audioBytes) {
            @Override
            public String getFilename() {
                return filename;
            }
        };

        MultiValueMap<String, Object> form = new LinkedMultiValueMap<>();
        form.add("file", resource);
        form.add("model", properties.getSttModel());
        form.add("response_format", "json");

        String responseBody = restClient.post()
                .uri("/audio/transcriptions")
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(form)
                .retrieve()
            .body(String.class);

        try {
            JsonNode response = objectMapper.readTree(responseBody);
            return response.at("/text").asText();
        } catch (Exception ex) {
            throw new IllegalStateException("OpenAI returned an invalid transcription response", ex);
        }
    }

    /** Generates speech audio (mp3) for the given text via the OpenAI TTS API. */
    public byte[] textToSpeech(String text, String voice) {
        Map<String, Object> body = Map.of(
                "model", properties.getTtsModel(),
                "voice", voice == null || voice.isBlank() ? properties.getTtsVoice() : voice,
                "input", text,
                "response_format", "mp3"
        );

        return restClient.post()
                .uri("/audio/speech")
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(byte[].class);
    }
}
