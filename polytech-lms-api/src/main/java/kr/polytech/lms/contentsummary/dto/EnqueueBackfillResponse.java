package kr.polytech.lms.contentsummary.dto;

public record EnqueueBackfillResponse(
    int scanned,
    int enqueued,
    int skippedDone
) {}

