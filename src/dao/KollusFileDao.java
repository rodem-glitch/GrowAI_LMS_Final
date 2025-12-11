package dao;

import malgnsoft.db.*;

public class KollusFileDao extends DataObject {

    public KollusFileDao() {
        this.table = "LM_KOLLUS_FILE";
        this.PK = "UPLOAD_FILE_KEY";
        this.setInsertIgnore(true);
    }


    public String getVideo(String uploadFileKey) {
        DataSet info = this.find("upload_file_key = ?", new String[] { uploadFileKey });
        if(!info.next()) return "";

        if("".equals(info.s("media_content_key"))) return "<p class=\"kollus_upload\">콜러스 영상을 업로드 중입니다.</p>";

        return "<iframe src=\"https://v.kr.kollus.com/" + info.s("media_content_key") + "\" width=\"1280\" height=\"720\" frameborder=\"0\" allowfullscreen webkitallowfullscreen mozallowfullscreen style=\"max-width:100%;\" allow=\"encrypted-media *; autoplay; fullscreen;\"></iframe>";
		}
}