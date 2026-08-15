package com.example.demo.services;

import com.example.demo.dto.CompleteReviewResponse;
import com.example.demo.dto.ImageExtractionResponse;
import com.example.demo.dto.SentenceBlockResponse;
import com.example.demo.dto.SentenceDTO;

import java.util.List;

public interface SentenceService {

    /** Extracts sentences from a Base64 image using OpenAI vision and stores them (FIFO). */
    ImageExtractionResponse extractFromImage(Long userId, String imageBase64);

    /** Returns the current block (max block-size) of due sentences plus the pending-now count. */
    SentenceBlockResponse getCurrentBlock(Long userId);

    List<SentenceDTO> getHistory(Long userId);

    /** Advances a sentence's Ebbinghaus interval after 20 correct repetitions in a session. */
    CompleteReviewResponse completeReview(Long userId, Long sentenceId);
}
