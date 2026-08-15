package com.example.demo.dto;

import java.util.List;

public record ImageExtractionResponse(
        List<SentenceDTO> createdSentences
) {
}
