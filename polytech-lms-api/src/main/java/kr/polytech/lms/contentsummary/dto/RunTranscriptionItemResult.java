package kr.polytech.lms.contentsummary.dto;

public record RunTranscriptionItemResult(
    String mediaContentKey,
    String title,
    String result,
    String message
) {}

