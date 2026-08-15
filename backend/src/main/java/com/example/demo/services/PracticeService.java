package com.example.demo.services;

import com.example.demo.dto.AudioValidationResponse;
import com.example.demo.dto.QuestionResponse;

public interface PracticeService {

    /** Generates a variable conversational question whose only logical answer is the sentence text. */
    QuestionResponse generateQuestion(Long userId, Long sentenceId);

    /** Transcribes the audio via Whisper and requires a 100% exact match against the sentence text. */
    AudioValidationResponse validateAudio(Long userId, Long sentenceId, byte[] audioBytes, String filename);

    /** Generates spoken audio (mp3) for the given text via the OpenAI TTS API. */
    byte[] textToSpeech(String text, String voice);
}
