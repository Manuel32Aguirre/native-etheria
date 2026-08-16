package com.example.demo.controllers;

import com.example.demo.domain.User;
import com.example.demo.dto.PracticeSettingsResponse;
import com.example.demo.dto.UpdatePracticeSettingsRequest;
import com.example.demo.exception.ResourceNotFoundException;
import com.example.demo.repositories.UserRepository;
import com.example.demo.security.UserPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/settings/practice")
@RequiredArgsConstructor
public class PracticeSettingsController {

    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<PracticeSettingsResponse> get(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(toResponse(findUser(principal.getId())));
    }

    @PostMapping
    public ResponseEntity<PracticeSettingsResponse> update(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody UpdatePracticeSettingsRequest request) {
        User user = findUser(principal.getId());
        user.setRequiredRepetitions(request.requiredRepetitions());
        user.setTtsVoice(request.voice());
        userRepository.save(user);
        return ResponseEntity.ok(toResponse(user));
    }

    private User findUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private PracticeSettingsResponse toResponse(User user) {
        return new PracticeSettingsResponse(user.getRequiredRepetitions(), user.getTtsVoice());
    }
}