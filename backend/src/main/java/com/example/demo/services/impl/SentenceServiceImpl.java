package com.example.demo.services.impl;

import com.example.demo.client.OpenAiClient;
import com.example.demo.config.ReviewProperties;
import com.example.demo.domain.ReviewLog;
import com.example.demo.domain.Sentence;
import com.example.demo.dto.CompleteReviewResponse;
import com.example.demo.dto.ImageExtractionResponse;
import com.example.demo.dto.SentenceBlockResponse;
import com.example.demo.dto.SentenceDTO;
import com.example.demo.exception.BadRequestException;
import com.example.demo.exception.ResourceNotFoundException;
import com.example.demo.mappers.SentenceMapper;
import com.example.demo.repositories.ReviewLogRepository;
import com.example.demo.repositories.SentenceRepository;
import com.example.demo.services.SentenceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SentenceServiceImpl implements SentenceService {

    private static final String STATUS_READY_NOW = "READY_NOW";
    private static final String STATUS_PENDING_NOW = "PENDING_NOW";

    private final SentenceRepository sentenceRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final SentenceMapper sentenceMapper;
    private final OpenAiClient openAiClient;
    private final ReviewProperties reviewProperties;

    @Override
    @Transactional
    public ImageExtractionResponse extractFromImage(Long userId, String imageBase64) {
        List<String> sentences = openAiClient.extractSentencesFromImage(imageBase64);
        if (sentences.isEmpty()) {
            throw new BadRequestException("No sentences could be extracted from the provided image");
        }

        Instant now = Instant.now();
        List<Sentence> saved = sentences.stream()
                .map(text -> Sentence.builder()
                        .userId(userId)
                        .originalText(text)
                        .intervalIndex(0)
                        .nextReviewAt(now) // FIFO: available for review immediately
                        .isMastered(false)
                        .createdAt(now)
                        .build())
                .map(sentenceRepository::save)
                .toList();

        List<SentenceDTO> dtos = saved.stream()
                .map(s -> sentenceMapper.toDtoWithStatus(s, STATUS_READY_NOW))
                .toList();

        return new ImageExtractionResponse(dtos);
    }

    @Override
    @Transactional(readOnly = true)
    public SentenceBlockResponse getCurrentBlock(Long userId) {
        Instant now = Instant.now();
        int blockSize = reviewProperties.getBlockSize();

        List<Sentence> due = sentenceRepository
                .findByUserIdAndIsMasteredFalseAndNextReviewAtLessThanEqualOrderByNextReviewAtAsc(userId, now);

        List<Sentence> currentBlock = due.stream().limit(blockSize).toList();
        int pendingNowCount = Math.max(0, due.size() - blockSize);

        List<SentenceDTO> blockDtos = currentBlock.stream()
                .map(s -> sentenceMapper.toDtoWithStatus(s, STATUS_READY_NOW))
                .toList();

        return new SentenceBlockResponse(blockDtos, pendingNowCount);
    }

        @Override
        @Transactional(readOnly = true)
        public List<SentenceDTO> getHistory(Long userId) {
                return sentenceRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                                .map(sentenceMapper::toDto)
                                .toList();
        }

    @Override
    @Transactional
    public CompleteReviewResponse completeReview(Long userId, Long sentenceId) {
        Sentence sentence = sentenceRepository.findById(sentenceId)
                .orElseThrow(() -> new ResourceNotFoundException("Sentence not found: " + sentenceId));

        if (!sentence.getUserId().equals(userId)) {
            throw new BadRequestException("Sentence does not belong to the current user");
        }

        List<Integer> intervals = reviewProperties.getIntervalMinutes();
        int previousIndex = sentence.getIntervalIndex();
        int newIndex = previousIndex + 1;
        boolean mastered = newIndex >= intervals.size();

        sentence.setIntervalIndex(Math.min(newIndex, intervals.size() - 1));
        sentence.setMastered(mastered);

        if (!mastered) {
            int minutesToAdd = intervals.get(newIndex);
            sentence.setNextReviewAt(Instant.now().plus(minutesToAdd, ChronoUnit.MINUTES));
        }

        sentenceRepository.save(sentence);

        reviewLogRepository.save(ReviewLog.builder()
                .sentenceId(sentence.getId())
                .userId(userId)
                .previousIntervalIndex(previousIndex)
                .newIntervalIndex(sentence.getIntervalIndex())
                .masteredAfterReview(mastered)
                .reviewedAt(Instant.now())
                .build());

        return new CompleteReviewResponse(
                sentence.getId(),
                previousIndex,
                sentence.getIntervalIndex(),
                mastered,
                mastered ? null : sentence.getNextReviewAt().toString()
        );
    }
}
