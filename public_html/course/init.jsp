<%@ include file="../init.jsp" %><%

String ch = m.rs("ch", "course");

// [중요] 카테고리별 전용 레이아웃 안전장치
// - 메뉴/링크에서 `ch=course{카테고리ID}` 형태로 넘겨받는 경우가 있는데,
//   해당 레이아웃 파일이 실제로 없으면 화면이 500 오류로 깨질 수 있습니다.
// - 그래서 파일이 없을 때는 기본 레이아웃(`course`)로 자동으로 되돌립니다.
File layoutFile = new File(tplRoot + "/layout/layout_" + ch + ".html");
if(!layoutFile.exists()) ch = "course";

p.setVar("ch", ch);

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"target_"});

%>
