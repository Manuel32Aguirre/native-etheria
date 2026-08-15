package com.example.demo.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "review_logs")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long sentenceId;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private int previousIntervalIndex;

    @Column(nullable = false)
    private int newIntervalIndex;

    @Column(nullable = false)
    private boolean masteredAfterReview;

    @Builder.Default
    @Column(nullable = false)
    private Instant reviewedAt = Instant.now();
}
