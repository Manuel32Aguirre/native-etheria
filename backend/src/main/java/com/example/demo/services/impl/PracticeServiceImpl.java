package com.example.demo.services.impl;

import com.example.demo.client.OpenAiClient;
import com.example.demo.domain.Sentence;
import com.example.demo.dto.AudioValidationResponse;
import com.example.demo.dto.QuestionResponse;
import com.example.demo.exception.BadRequestException;
import com.example.demo.exception.ResourceNotFoundException;
import com.example.demo.repositories.SentenceRepository;
import com.example.demo.services.PracticeService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;

@Service
@RequiredArgsConstructor
public class PracticeServiceImpl implements PracticeService {

    private final SentenceRepository sentenceRepository;
    private final OpenAiClient openAiClient;

    @Override
    @Transactional
    public QuestionResponse generateQuestion(Long userId, Long sentenceId) {
        Sentence sentence = findOwnedSentence(userId, sentenceId);
        String question = sentence.getPracticeQuestion();
        if (question == null || question.isBlank()) {
            question = openAiClient.generateVariableQuestion(sentence.getOriginalText());
            sentence.setPracticeQuestion(question);
        }
        return new QuestionResponse(sentence.getId(), question);
    }

    @Override
    @Transactional(readOnly = true)
    public AudioValidationResponse validateAudio(Long userId, Long sentenceId, byte[] audioBytes, String filename) {
        if (audioBytes == null || audioBytes.length == 0) {
            throw new BadRequestException("Audio file is empty");
        }

        Sentence sentence = findOwnedSentence(userId, sentenceId);
        String transcript = openAiClient.transcribeAudio(audioBytes, filename);

        boolean isExactMatch = normalize(transcript).equals(normalize(sentence.getOriginalText()));

        return new AudioValidationResponse(isExactMatch, transcript, sentence.getOriginalText());
    }

    @Override
    public byte[] textToSpeech(String text, String voice) {
        if (text == null || text.isBlank()) {
            throw new BadRequestException("Text is required for speech synthesis");
        }
        return openAiClient.textToSpeech(text, voice);
    }

    private Sentence findOwnedSentence(Long userId, Long sentenceId) {
        Sentence sentence = sentenceRepository.findById(sentenceId)
                .orElseThrow(() -> new ResourceNotFoundException("Sentence not found: " + sentenceId));
        if (!sentence.getUserId().equals(userId)) {
            throw new BadRequestException("Sentence does not belong to the current user");
        }
        return sentence;
    }

    /** Zero-tolerance word comparison that ignores punctuation Whisper cannot reliably transcribe. */
    private String normalize(String text) {
        return Normalizer.normalize(text, Normalizer.Form.NFKC)
                .toLowerCase(java.util.Locale.ROOT)
                .replaceAll("['’]", "")
                .replaceAll("[^\\p{L}\\p{N}]+", " ")
                .trim()
                .replaceAll("\\s+", " ");
    }
}
