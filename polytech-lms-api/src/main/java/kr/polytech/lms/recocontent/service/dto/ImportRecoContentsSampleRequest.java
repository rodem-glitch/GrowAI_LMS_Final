package kr.polytech.lms.recocontent.service.dto;

public record ImportRecoContentsSampleRequest(
    String sampleText,
    boolean replace
) {}

