package com.example.demo.dto;

public record AuthResponse(
        String token,
        Long userId,
        String username,
        boolean verificationRequired
) {
}
