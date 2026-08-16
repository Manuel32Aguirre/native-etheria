package com.example.demo.services;

import com.example.demo.dto.AudioValidationResponse;
import com.example.demo.dto.QuestionResponse;

public interface PracticeService {

    /** Generates a variable conversational question whose only logical answer is the sentence text. */
    QuestionResponse generateQuestion(Long userId, Long sentenceId);

    /** Transcribes practice audio (local Whisper or OpenAI) and requires an exact word match. */
    AudioValidationResponse validateAudio(Long userId, Long sentenceId, byte[] audioBytes, String filename);

    /** Validates the final transcript produced by the device speech recognizer. */
    AudioValidationResponse validateTranscript(Long userId, Long sentenceId, String transcript);

    /** Returns cached question audio, generating it only when its voice changes. */
    byte[] getQuestionAudio(Long userId, Long sentenceId, String voice);

    /** Generates spoken audio (mp3) for the given text via the OpenAI TTS API. */
    byte[] textToSpeech(String text, String voice);
}
