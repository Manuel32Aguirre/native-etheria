package com.example.demo.repositories;

import com.example.demo.domain.ReviewLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReviewLogRepository extends JpaRepository<ReviewLog, Long> {

    List<ReviewLog> findBySentenceIdOrderByReviewedAtDesc(Long sentenceId);
}
