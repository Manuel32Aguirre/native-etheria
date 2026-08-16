package com.example.demo.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record UpdatePracticeSettingsRequest(
        @Min(1) @Max(100) int requiredRepetitions,
        @NotBlank String voice
) {
}
