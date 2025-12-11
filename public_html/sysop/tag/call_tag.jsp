<%@ page contentType="text/html; charset=utf-8" %><%@ page import="malgnsoft.json.*" %><%@ include file="init.jsp" %><%

//기본키
String module = m.rs("module");
int moduleId = m.ri("module_id");

//객체
TagDao tag = new TagDao(siteId);
TagModuleDao tagModule = new TagModuleDao(module);
Json j = new Json(out);

//변수
String mode = m.rs("mode");
int tagId;
String moduleNm = Malgn.getItem(module, tagModule.moduleList);

//print(int code, String message)
if(moduleId < 1 || "".equals(module)) { j.print(-1, "기본키는 반드시 지정하여야 합니다."); return; }

if(m.isPost()) {
	if("add".equals(mode)) {
		String tagNm = f.get("tag_nm");

		if("".equals(tagNm)) {
			j.print(-1, "태그명이 없습니다.");
			return;
		}

		//확인-태그등록여부
		DataSet tinfo = tag.find("tag_nm = ? AND site_id = ?", new Object[] { tagNm, siteId });
		if(!tinfo.next()) {
			//등록-태그
			tagId = tag.add(tagNm);
			if(tagId < 1) { //등록 실패
				j.print(-1, "태그를 등록하는 중 오류가 발생했습니다.");
				return;
			}
		} else {
			tagId = tinfo.i("id");
			if(tinfo.i("status") == -1) {
				tag.item("status", 1);
				tag.update("id = " + tagId + "");
			}
		}

		if(tagId > 0) { //있으면

			//확인-모듈등록여부
			DataSet info = tagModule.find("tag_id = ? AND module = ? AND module_id = ?", new Object[] { tagId, module, moduleId });
			if(info.next() && tinfo.i("status") != -1) { //이미 등록된 모듈
				j.print(-1, "이미 등록된 태그입니다.");
				return;
			}

			//등록-모듈태그
			if (tinfo.i("status") != -1 && !tagModule.addTag(tagId, moduleId)) {
				j.print(-1, "태그를 과정에 등록하는 중 오류가 발생 했습니다.");
				return;
			}

			j.put("tag_id", tagId);
			j.print(0, "태그가 등록 되었습니다.");
		}
	} else if("del".equals(mode)) {
		tagId = f.getInt("tag_id", 0);
		//확인-기본키
		if(tagId == 0) {
			j.print(-1, "삭제하려는 태그를 확인할 수 없습니다.");
			return;
		}

		//확인-태그등록여부
		DataSet tinfo = tag.find("id = ?", new Object[] { tagId });
		if(!tinfo.next()) {
			j.print(-1, "등록되지 않은 태그 입니다.");
			return;
		}

		//확인-모듈등록여부
		DataSet info = tagModule.find("tag_id = ? AND module = ? AND module_id = ?", new Object[] { tagId, module, moduleId });
		if(!info.next()) {
			j.print(-1, moduleNm + "에 등록되지 않은 태그 입니다.");
			return;
		}

		//삭제-모듈태그
		boolean isDeleted = tagModule.delete("tag_id = ? AND module = ? AND module_id = ?", new Object[] { tagId, module, moduleId });
		if(!isDeleted) {
			j.print(-1, moduleNm + "에 등록된 태그를 삭제하는 중 오류가 발생했습니다.");
			return;
		}

		j.put("tag_id", tagId);
		j.print(0, "삭제하였습니다.");
	} else if("list".equals(mode)) {
		int tagItemLimit = 100;
		JSONArray tagModuleArr = new JSONArray(
			tagModule.query(
				"SELECT t.id, t.tag_nm "
				+ " FROM " + tag.table + " t "
				+ " INNER JOIN " + tagModule.table + " tm ON tm.tag_id = t.id AND tm.module = '" + module + "' AND module_id = " + moduleId + ""
				+ " WHERE t.status = 1 "
				+ " ORDER BY t.sort ASC, t.tag_nm ASC, t.id ASC "
				, tagItemLimit
			)
		);

		j.put("data_list", tagModuleArr);
		j.print(0, "등록된 태그 목록 출력");
	}
}

%>