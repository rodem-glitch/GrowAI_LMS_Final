package kr.polytech.lms.recocontent.service.dto;

public record ImportRecoContentsResponse(
    int parsedCount,
    int savedCount
) {}

