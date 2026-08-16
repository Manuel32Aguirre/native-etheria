package com.example.demo.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "sentences")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Sentence {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Lob
    @Column(nullable = false)
    private String originalText;

    @Lob
    private String practiceQuestion;

    @Column(columnDefinition = "bytea")
    private byte[] practiceQuestionAudio;

    private String practiceQuestionAudioVoice;

    @Builder.Default
    @Column(nullable = false)
    private int intervalIndex = 0;

    @Column(nullable = false)
    private Instant nextReviewAt;

    @Builder.Default
    @Column(nullable = false)
    private boolean isMastered = false;

    @Builder.Default
    @Column(nullable = false)
    private Instant createdAt = Instant.now();
}
