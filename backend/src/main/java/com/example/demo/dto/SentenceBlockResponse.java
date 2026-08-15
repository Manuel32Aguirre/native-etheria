package com.example.demo.dto;

import java.util.List;

public record SentenceBlockResponse(
        List<SentenceDTO> currentBlock,
        int pendingNowCount
) {
}
