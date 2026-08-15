package com.example.demo.dto;

import jakarta.validation.constraints.NotBlank;

public record ResendVerificationRequest(@NotBlank String username) {
}