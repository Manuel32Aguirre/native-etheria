package com.example.demo.repositories;

import com.example.demo.domain.Sentence;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface SentenceRepository extends JpaRepository<Sentence, Long> {

    /** FIFO order: oldest due sentences first. */
    List<Sentence> findByUserIdAndIsMasteredFalseAndNextReviewAtLessThanEqualOrderByNextReviewAtAsc(
            Long userId, Instant now);

    long countByUserIdAndIsMasteredFalseAndNextReviewAtLessThanEqual(Long userId, Instant now);

    List<Sentence> findByUserIdOrderByCreatedAtDesc(Long userId);
}
