package com.example.demo.dto;

public record CompleteReviewResponse(
        Long sentenceId,
        int previousIntervalIndex,
        int newIntervalIndex,
        boolean isMastered,
        String nextReviewAt
) {
}
