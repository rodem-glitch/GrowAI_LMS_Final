<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%@ page import="java.io.File" %><%@ page import="java.awt.image.BufferedImage, javax.imageio.ImageIO" %><%@ page import="com.google.zxing.qrcode.QRCodeWriter, com.google.zxing.common.BitMatrix, com.google.zxing.BarcodeFormat, com.google.zxing.client.j2se.MatrixToImageWriter" %><%

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int lid = m.ri("lid");
int chapter = m.ri("chapter");
if(1 > lid && 1 > chapter) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//객체
LessonDao lesson = new LessonDao();
CourseLessonDao courseLesson = new CourseLessonDao();
QRCodeWriter writer = new QRCodeWriter();

//차시 정보
//courseLesson.d(out);
DataSet info = courseLesson.query(
    " SELECT a.*, le.lesson_nm, le.lesson_type "
    + " FROM " + courseLesson.table + " a "
    + " INNER JOIN " + lesson.table + " le ON a.lesson_id = le.id AND le.site_id = " + siteId + " "
    + " WHERE a.status != -1 AND a.course_id = " + courseId + " AND a.lesson_id = " + lid + " AND a.chapter = " + chapter + " "
    + " AND le.onoff_type = 'F' AND le.lesson_type IN ('11', '12', '13', '14') "
);
if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("expire_time", 10, "hname:'유효시간(분)', required:'Y'");

//변수
boolean qrBlock = false;
String qrUrl = "";
String attendUrl = "";
String validTime = "";

if(m.isPost() && f.validate()) {
    //QR
    String baseTime = m.time("yyyyMMddHHmm") + "00";
    String k = m.encode(SimpleAES.encrypt(baseTime));
    String ek = m.encrypt("CLASSROOM_" + courseId + "_CHAPTER_" + chapter + "_ATTEND_" + baseTime);
    String protocol = siteinfo.b("ssl_yn") ? "https://" : "http://";
    attendUrl = protocol + siteinfo.s("domain") + "/classroom/attend_insert.jsp?cid=" + courseId + "&lid=" + lid + "&chapter=" + chapter + "&k=" + k + "&ek=" + ek;
    File path = new File(dataDir + "/qrcode/");
    String qrFileName = "site_" + siteId + "_attend_" + courseId + "_" + lid + "_" + chapter + "_" + baseTime;
    if(!path.exists()) path.mkdirs();

    //생성
    BitMatrix qrCode = writer.encode(attendUrl, BarcodeFormat.QR_CODE, 250, 250);
    BufferedImage qrImage = MatrixToImageWriter.toBufferedImage(qrCode);
    ImageIO.write(qrImage, "PNG", new File(path, qrFileName + ".png"));

    qrBlock = true;
    qrUrl = request.getContextPath() + "/data/qrcode/" + qrFileName + ".png";
    validTime = m.addDate("I", f.getInt("expire_time"), baseTime, "yyyy.MM.dd HH:mm");
}

//출력
p.setLayout("poplayer");
p.setBody("management.attend_qr");
p.setVar("form_script", f.getScript());
p.setVar("p_title", info.s("chapter") + "차시 " + info.s("lesson_nm") + " 출석코드");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar("attend_url", attendUrl);
p.setVar("valid_time_conv", validTime);
p.setVar("qr_url", qrUrl);
p.setVar("qr_block", qrBlock);
p.display();

%>