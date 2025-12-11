<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
KollusDao kollus = new KollusDao(siteId);
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();
//kollus.d(out);
if(2 == m.ri("version")) kollus.setApiVersion("api-vod");

DataSet list = null;
if(!error) {
    //목록-채널
    String channelKey = "";
    DataSet channels = kollus.getChannels();
    if(null == channels || 1 > channels.size()) {
        m.jsError("채널을 불러올 수 없습니다. 관리자에게 문의바랍니다.");
        return;
    }

    channelKey = kollus.getChannelKey(channels, "폴리텍대학");
    channelKey = m.rs("s_channel", channelKey);
    //채널키를 못 찾은 경우 사이트설정이 되어있는 채널키를 사용하거나 첫번째 채널키를 사용
    if("".equals(channelKey)) {
        if(!"".equals(siteinfo.s("kollus_channel"))) {
            channelKey = siteinfo.s("kollus_channel");
        } else {
            channels.first();
            channels.next();
            channelKey = channels.s("key");
        }
    }

    if("".equals(channelKey)) {
        m.jsError("유효한 채널이 존재하지 않습니다. 관리자에게 문의바랍니다.");
        return;
    }


    //목록-카테고리
    String categoryKey = m.rs("ckey");
    if (categoryKey == "") { categoryKey = "u8p6y0itgnuaemiy"; }
    DataSet categories = kollus.getCategories();
    if(null == categories || 1 > categories.size()) {
        m.jsError("카테고리를 불러올 수 없습니다. 관리자에게 문의바랍니다.");
        return;
    }
    HashMap<String, String> categoryMap = new HashMap<String, String>();
    while(categories.next()) {
        categoryMap.put(categories.s("key"), categories.s("name"));
    }
    categories.first();
    // 카테고리키는 임시로 LMS로 넣음
    //categoryKey = "u8p6y0itgnuaemiy";
    kollus.setCategoryKey(categoryKey);

    //폼체크
    f.addElement("s_channel", channelKey, null);
    f.addElement("s_category", categoryKey, null);
    f.addElement("s_field", null, null);
    f.addElement("s_keyword", null, null);
    int pg = m.ri("page") > 0 ? m.ri("page") : 1;
    //m.p(m.rs("s_category"));

    //목록
    list = kollus.getContents(channelKey, m.rs("s_keyword"), pg, 20);
    int totalNum = kollus.getTotalNum();
    int i = 1;
    //m.p(list);
    while(list.next()) {
        //m.p(list.getRow());
        list.put("__ord", i++);
        list.put("ROW_CLASS", i % 2 == 1 ? "odd" : "even");

        //api
        list.put("category_nm", categoryMap.containsKey(list.s("category_key")) ? categoryMap.get(list.s("category_key")) : "-");
        list.put("previewurl", request.getScheme() + "://" + siteinfo.s("domain") + "/kollus/preview.jsp?key="+list.get("media_content_key"));
        list.put("use_encryption_conv", "1".equals(list.s("use_encryption")) ? "Y" : "N");
        list.put("encrypt_block", "1".equals(list.s("use_encryption")));

        if(!"".equals(list.s("duration")) && -1 < list.s("duration").indexOf(":")) {
            String[] duration = m.split(":", list.s("duration"));

            list.put("total_time", m.parseInt(duration[0]) * 60 + m.parseInt(duration[1]));
        } else {
            list.put("duration", "-");
            list.put("total_time", "0");
        }

        list.put("content_width", "0");
        list.put("content_height", "0");
        if(!"".equals(list.s("transcoding_files"))) {
            DataSet tfinfo = Json.decode(list.s("transcoding_files"));

            while(tfinfo.next()) {
                if(-1 < tfinfo.s("media_profile_group_key").toLowerCase().indexOf("pc")) {
                    DataSet minfo = Json.decode(tfinfo.s("media_information"));
                    while(minfo.next()) {
                        DataSet vinfo = Json.decode(minfo.s("video"));
                        if(vinfo.next() && !"".equals(vinfo.s("video_screen_size")) && -1 < vinfo.s("video_screen_size").indexOf("x")) {
                            String[] size = m.split("x", vinfo.s("video_screen_size"));
                            list.put("content_width", size[0]);
                            list.put("content_height", size[1]);
                        }
                    }
                }
            }
        }
        _ret.put("ret_size", list.size());
    }
}
//출력
apiLog.printList(out, _ret, list);
%>