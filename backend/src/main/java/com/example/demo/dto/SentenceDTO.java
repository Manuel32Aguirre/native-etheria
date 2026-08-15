package com.example.demo.dto;

import java.time.Instant;

public record SentenceDTO(
        Long id,
        String originalText,
        int intervalIndex,
        Instant nextReviewAt,
        boolean isMastered,
        String status
) {
}
