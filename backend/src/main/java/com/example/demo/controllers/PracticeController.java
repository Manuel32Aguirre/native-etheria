package com.example.demo.controllers;

import com.example.demo.dto.AudioValidationResponse;
import com.example.demo.dto.QuestionResponse;
import com.example.demo.exception.BadRequestException;
import com.example.demo.security.UserPrincipal;
import com.example.demo.services.PracticeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/api/practice")
@RequiredArgsConstructor
public class PracticeController {

    private final PracticeService practiceService;

    @GetMapping("/{sentenceId}/question")
    public ResponseEntity<QuestionResponse> generateQuestion(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long sentenceId) {
        return ResponseEntity.ok(practiceService.generateQuestion(principal.getId(), sentenceId));
    }

    @PostMapping(value = "/{sentenceId}/validate-audio", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<AudioValidationResponse> validateAudio(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long sentenceId,
            @RequestParam("audio") MultipartFile audio) {
        try {
            String filename = audio.getOriginalFilename() != null ? audio.getOriginalFilename() : "audio.m4a";
            AudioValidationResponse response = practiceService.validateAudio(
                    principal.getId(), sentenceId, audio.getBytes(), filename);
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            throw new BadRequestException("Could not read uploaded audio file");
        }
    }

    @PostMapping("/{sentenceId}/validate-text")
    public ResponseEntity<AudioValidationResponse> validateText(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long sentenceId,
            @RequestBody TextValidationRequest request) {
        return ResponseEntity.ok(practiceService.validateTranscript(
                principal.getId(), sentenceId, request.transcript()));
    }

    @PostMapping(value = "/tts", produces = "audio/mpeg")
    public ResponseEntity<byte[]> textToSpeech(@RequestBody TtsRequest request) {
        byte[] audio = practiceService.textToSpeech(request.text(), request.voice());
        return ResponseEntity.ok()
                .contentType(MediaType.valueOf("audio/mpeg"))
                .body(audio);
    }

    public record TtsRequest(String text, String voice) {
    }

    public record TextValidationRequest(String transcript) {
    }
}
