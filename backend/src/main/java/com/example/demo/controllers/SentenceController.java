package com.example.demo.controllers;

import com.example.demo.dto.CompleteReviewResponse;
import com.example.demo.dto.ImageExtractionRequest;
import com.example.demo.dto.ImageExtractionResponse;
import com.example.demo.dto.SentenceBlockResponse;
import com.example.demo.security.UserPrincipal;
import com.example.demo.services.SentenceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sentences")
@RequiredArgsConstructor
public class SentenceController {

    private final SentenceService sentenceService;

    @PostMapping("/extract-image")
    public ResponseEntity<ImageExtractionResponse> extractFromImage(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody ImageExtractionRequest request) {
        return ResponseEntity.ok(sentenceService.extractFromImage(principal.getId(), request.imageBase64()));
    }

    @GetMapping("/block")
    public ResponseEntity<SentenceBlockResponse> getCurrentBlock(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(sentenceService.getCurrentBlock(principal.getId()));
    }

    @GetMapping("/history")
    public ResponseEntity<List<com.example.demo.dto.SentenceDTO>> getHistory(
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(sentenceService.getHistory(principal.getId()));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<CompleteReviewResponse> completeReview(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable("id") Long sentenceId) {
        return ResponseEntity.ok(sentenceService.completeReview(principal.getId(), sentenceId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSentence(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable("id") Long sentenceId) {
        sentenceService.deleteSentence(principal.getId(), sentenceId);
        return ResponseEntity.noContent().build();
    }
}
