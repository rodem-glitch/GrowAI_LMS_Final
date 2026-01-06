package kr.polytech.lms.recocontent.controller;

import kr.polytech.lms.recocontent.service.RecoContentImportService;
import kr.polytech.lms.recocontent.service.RecoContentVectorIndexService;
import kr.polytech.lms.recocontent.service.dto.ImportRecoContentsSampleRequest;
import kr.polytech.lms.recocontent.service.dto.ImportRecoContentsResponse;
import kr.polytech.lms.recocontent.service.dto.IndexRecoContentsRequest;
import kr.polytech.lms.recocontent.service.dto.IndexRecoContentsResponse;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/reco-contents/admin")
public class RecoContentAdminController {

    private final RecoContentImportService recoContentImportService;
    private final RecoContentVectorIndexService recoContentVectorIndexService;

    public RecoContentAdminController(
        RecoContentImportService recoContentImportService,
        RecoContentVectorIndexService recoContentVectorIndexService
    ) {
        // 왜: 개발 단계에서 "샘플 적재 + 벡터 인덱싱"을 빠르게 반복할 수 있는 관리용 API를 분리합니다.
        this.recoContentImportService = recoContentImportService;
        this.recoContentVectorIndexService = recoContentVectorIndexService;
    }

    @PostMapping(
        value = "/import/sample-text",
        consumes = MediaType.TEXT_PLAIN_VALUE,
        produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ImportRecoContentsResponse importSampleText(
        @RequestParam(name = "replace", defaultValue = "false") boolean replace,
        @RequestBody(required = false) String sampleText
    ) {
        return recoContentImportService.importFromSampleText(sampleText, replace);
    }

    @PostMapping(
        value = "/import/sample",
        consumes = MediaType.APPLICATION_JSON_VALUE,
        produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ImportRecoContentsResponse importSample(@RequestBody(required = false) ImportRecoContentsSampleRequest request) {
        // 왜: 화면/배치에서 옵션까지 함께 보내려면 JSON 형식이 더 안전합니다.
        return recoContentImportService.importFromSampleRequest(request);
    }

    @PostMapping("/index")
    public IndexRecoContentsResponse index(@RequestBody(required = false) IndexRecoContentsRequest request) {
        return recoContentVectorIndexService.indexFromDatabase(request);
    }
}
