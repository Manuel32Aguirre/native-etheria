package com.example.demo.dto;

public record AudioValidationResponse(
        boolean isExactMatch,
        String transcript,
        String expectedText
) {
}
