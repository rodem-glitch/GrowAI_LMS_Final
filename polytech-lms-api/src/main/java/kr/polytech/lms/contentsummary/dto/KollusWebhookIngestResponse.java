package kr.polytech.lms.contentsummary.dto;

public record KollusWebhookIngestResponse(
    String mediaContentKey,
    String title,
    String action
) {}

