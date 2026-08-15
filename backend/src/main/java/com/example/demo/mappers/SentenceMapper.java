package com.example.demo.mappers;

import com.example.demo.domain.Sentence;
import com.example.demo.dto.SentenceDTO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface SentenceMapper {

    @Mapping(target = "status", constant = "SCHEDULED")
    SentenceDTO toDto(Sentence sentence);

    default SentenceDTO toDtoWithStatus(Sentence sentence, String status) {
        SentenceDTO base = toDto(sentence);
        return new SentenceDTO(
                base.id(),
                base.originalText(),
                base.intervalIndex(),
                base.nextReviewAt(),
                base.isMastered(),
                status
        );
    }
}
