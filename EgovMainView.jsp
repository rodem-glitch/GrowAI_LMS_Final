<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../layout/top.jsp" %>
    <div class="p_main">
        <section class="position-relative from-blue-50 via-white to-blue-50 text-gray-900 pt-5 pb-4 main-img">
            <div class="max-w-7xl mx-auto px-4 px-sm-5 px-lg-5">
                <div class="w-full text-center">
                    <h3 class="fw-bold mb-6 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent mb-4">
                        한국폴리텍대학 미래형 직업교육 플랫폼
                    </h3>
                    <form class="d-flex mb-4" method="post" action="#LINK" name="TopSearchForm" id="TopSearchForm">
                        <div class="input-group flex-nowrap h_60 rounded-start-4">
                            <span class=" rounded-start-5 input-group-text bg-gray-50 ps-4" id="addon-wrapping">
                                <img src="/images/ui_symbol.png" class="h_40" alt="uisymbol">
                            </span>
                            <input type="text" class="form-control bg-gray-50 border-start-0 border-end-0" placeholder="강의, 진로, 기업 검색..." aria-label="Username" aria-describedby="addon-wrapping">
                            <span class="rounded-end-5 input-group-text bg-gray-50 pe-4" id="addon-wrapping2"><i class="bi bi-search"></i></span>
                        </div>
                    </form>
                    <!--h1 class="text-5xl md:text-6xl fw-bold mb-6 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                        한국폴리텍대학<br>미래형 직업교육 플랫폼
                    </h1>
                    <p class="text-xl my-4 text-gray-600 max-w-3xl mx-auto">
                        성공적인 커리어 목표 달성을 위해<br>맞춤형 강의와 직업 정보를 제공해 드립니다.
                    </p-->
                    <div class="d-flex flex-md-row flex-sm-column gap-4 justify-content-center pt-2">
                        <button id="btnMyInterest" class="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-5 py-3 rounded-2 fw-semibold shadow-lg">
                            <i class="bi bi-person-check"></i>
                            나의 관심사
                        </button>
                        <button class="border-2 border-gray-300 text-gray-700 px-5 py-3 rounded-2 fw-semibold bg-transparent">
                            <i class="bi bi-search"></i>
                            둘러보기
                        </button>
                    </div>
                </div>
            </div>
        </section>

        <section>
            <div class="mt-5 container-fluid container-lg">
                <ul id="middle-nav" class="nav">
                    <li class="nav-item">
                        <a class="nav-link btn btn-outline-secondary rounded-5 px-3 active" aria-current="page" href="#">
                            <i class="bi bi-grid"></i>
                            전체
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link btn btn-outline-secondary rounded-5 px-3 mx-1 border-1" href="#fire">
                            <i class="bi bi-fire"></i>
                            인기 급상승
                        </a>
                    </li>
                    <!--li class="nav-item">
                        <a class="nav-link btn btn-outline-secondary rounded-5 px-3 mx-1 border-secondary" href="#recommend">
                            <i class="bi bi-star"></i>
                            추천 강의
                        </a>
                    </li-->
                    <li class="nav-item">
                        <a class="nav-link btn btn-outline-secondary rounded-5 px-3 mx-1 border-1" href="#recommendmov">
                            <i class="bi bi-play-btn"></i>
                            추천 영상
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link btn btn-outline-secondary rounded-5 px-3 mx-1 border-1" href="#shorts">
                            <i class="bi bi-play-btn"></i>
                            숏폼
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link btn btn-outline-secondary rounded-5 px-3 mx-1 border-1" href="#contentsmov">
                            <i class="bi bi-play-btn"></i>
                            콘텐츠
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link btn btn-outline-secondary rounded-5 px-3 mx-1 border-1" href="#continue">
                            <i class="bi bi-play-circle"></i>
                            계속 학습하기
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link btn btn-outline-secondary rounded-5 px-3 mx-1 border-1" href="#boardfile">
                            <i class="bi bi-play-circle"></i>
                            연구보고서
                        </a>
                    </li>
                </ul>

                <div class="d-flex justify-content-between mt-5 mb-3">
                    <h4 id="fire" class="fw-bold">
                        인기 급상승
                    </h4>
                    <a href="">
                        <small>더보기</small>
                    </a>
                </div>
                <div class="row g-3 mb-5">
                    <!--리스트 부분-->
                    <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                        <div class="card rounded-3 shadow-sm shadow-sm-hover">
                            <img src="/images/img5.jpg" class="card-img-top" alt="반도체 공정 기초">
                            <div class="card-body">
                                <h6 class="card-title fw-bold">메타버스 개발</h6>
                                <p class="card-text">장교수</p>
                                <div class="d-flex justify-content-between">
                                    <div>
                                        <i class="bi bi-star-fill text-yellow-400"></i>
                                        4.8
                                        <span class="text-gray-500">(245)</span>
                                    </div>
                                    <div class="text-red-500">
                                        <i class="bi bi-fire"></i>
                                        HOT
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                        <div class="card rounded-3 shadow-sm shadow-sm-hover">
                            <img src="/images/img1.jpg" class="card-img-top" alt="반도체 공정 기초">
                            <div class="card-body">
                                <h6 class="card-title fw-bold">반도체 공정 기초</h6>
                                <p class="card-text">이교수</p>
                                <div class="d-flex justify-content-between">
                                    <div>
                                        <i class="bi bi-star-fill text-yellow-400"></i>
                                        4.8
                                        <span class="text-gray-500">(245)</span>
                                    </div>
                                    <div class="text-red-500">
                                        <i class="bi bi-fire"></i>
                                        HOT
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                        <div class="card rounded-3 shadow-sm shadow-sm-hover">
                            <img src="/images/img3.jpg" class="card-img-top" alt="반도체 공정 기초">
                            <div class="card-body">
                                <h6 class="card-title fw-bold">메타버스 개발</h6>
                                <p class="card-text">이교수</p>
                                <div class="d-flex justify-content-between">
                                    <div>
                                        <i class="bi bi-star-fill text-yellow-400"></i>
                                        4.8
                                        <span class="text-gray-500">(245)</span>
                                    </div>
                                    <div class="text-red-500">
                                        <i class="bi bi-fire"></i>
                                        HOT
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                        <div class="card rounded-3 shadow-sm shadow-sm-hover">
                            <img src="/images/img2.jpg" class="card-img-top" alt="반도체 공정 기초">
                            <div class="card-body">
                                <h6 class="card-title fw-bold">메타버스 개발</h6>
                                <p class="card-text">박교수</p>
                                <div class="d-flex justify-content-between">
                                    <div>
                                        <i class="bi bi-star-fill text-yellow-400"></i>
                                        4.8
                                        <span class="text-gray-500">(245)</span>
                                    </div>
                                    <div class="text-red-500">
                                        <i class="bi bi-fire"></i>
                                        HOT
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!--리스트 부분-->
                </div>

                <div class="my-4" tabindex="0">
                    <!--div class="d-flex justify-content-between mb-3">
                        <h4 id="recommend" class="fw-bold">
                            추천 강의
                        </h4>
                        <a href="">
                            <small>더보기</small>
                        </a>
                    </div>
                    <div class="row g-3">
                        리스트 부분
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img1.jpg" class="card-img-top" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">반도체 공정 기초</h6>
                                    <p class="card-text">김교수</p>
                                    <a class="icon-link text-black" href="#">
                                        <i class="bi bi-star-fill text-yellow-400"></i>
                                        4.8
                                        <span class="text-gray-500">(245)</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                        리스트 부분
                    </div-->


                    <div class="d-flex justify-content-between mt-5 mb-3">
                        <h4 id="recommendmov" class="fw-bold">
                            추천 영상
                        </h4>
                        <a href="">
                            <small>더보기</small>
                        </a>
                    </div>
                    <!-- 추천 영상 리스트가 동적으로 들어갈 영역입니다. -->
                    <div id="recommendMovList" class="row g-3">
                        <!--리스트 부분-->
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img2.jpg" class="card-img-top" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">반도체 공정의 모든 것 - 삼성전자 엔지니어가 설명하는 실무</h6>
                                    <p class="card-text">테크 인사이드</p>
                                    <a class="icon-link text-black d-flex justify-content-between" href="#">
                                        1.2M 조회수
                                        <span class="text-gray-500">1일 전</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img5.jpg" class="card-img-top" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">AI 반도체 설계 혁신 - NVIDIA GPU 아키텍처 분석</h6>
                                    <p class="card-text">AI Tech Review</p>
                                    <a class="icon-link text-black d-flex justify-content-between" href="#">
                                        0.7M 조회수
                                        <span class="text-gray-500">2일 전</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img4.jpg" class="card-img-top" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">스마트팩토리 현장 투어 - 현대자동차 울산공장</h6>
                                    <p class="card-text">산업 현장</p>
                                    <a class="icon-link text-black d-flex justify-content-between" href="#">
                                        1.0M 조회수
                                        <span class="text-gray-500">3일 전</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img3.jpg" class="card-img-top" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">전자공학과 졸업생의 취업 성공기 - 대기업 합격 노하우</h6>
                                    <p class="card-text">커리어 멘토</p>
                                    <a class="icon-link text-black d-flex justify-content-between" href="#">
                                        1.2M 조회수
                                        <span class="text-gray-500">3일 전</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <!--리스트 부분-->
                    </div>

                    <div class="d-flex justify-content-between mt-5 mb-3">
                        <h4 id="shorts" class="fw-bold">
                            숏폼
                        </h4>
                        <a href="">
                            <small>더보기</small>
                        </a>
                    </div>
                    <div class="row g-3">
                        <!--리스트 부분-->
                        <c:forEach var="item" items="${ytiList}" varStatus="status">
                            <div class="col-6 col-sm-4 col-md-3 col-lg-3 col-xl-2">
                                <div class="card rounded-3 shadow-sm shadow-sm-hover" data-youtubeid="${item.id}" alt="${item.title}">
                                    <div class="card-img-top h_300 bgimgcenter"  style="background:url('${item.thumbnailUrl}')"></div>
<%--                                    <iframe width="100%" height="100%" src="https://www.youtube.com/embed/${item.id}" class="card-img-top h_300" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>--%>
<%--                                    <img src="${item.thumbnailUrl}" class="card-img-top h_300" alt="${item.title}">--%>
                                    <div class="youtubebtn">
                                        <i class="bi bi-youtube"></i>
                                        <!--svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" fill="currentColor" class="bi bi-youtube" viewBox="0 0 16 16">
                                            <path d="M8.051 1.999h.089c.822.003 4.987.033 6.11.335a2.01 2.01 0 0 1 1.415 1.42c.101.38.172.883.22 1.402l.01.104.022.26.008.104c.065.914.073 1.77.074 1.957v.075c-.001.194-.01 1.108-.082 2.06l-.008.105-.009.104c-.05.572-.124 1.14-.235 1.558a2.01 2.01 0 0 1-1.415 1.42c-1.16.312-5.569.334-6.18.335h-.142c-.309 0-1.587-.006-2.927-.052l-.17-.006-.087-.004-.171-.007-.171-.007c-1.11-.049-2.167-.128-2.654-.26a2.01 2.01 0 0 1-1.415-1.419c-.111-.417-.185-.986-.235-1.558L.09 9.82l-.008-.104A31 31 0 0 1 0 7.68v-.123c.002-.215.01-.958.064-1.778l.007-.103.003-.052.008-.104.022-.26.01-.104c.048-.519.119-1.023.22-1.402a2.01 2.01 0 0 1 1.415-1.42c.487-.13 1.544-.21 2.654-.26l.17-.007.172-.006.086-.003.171-.007A100 100 0 0 1 7.858 2zM6.4 5.209v4.818l4.157-2.408z"/>
                                        </svg-->
                                    </div>
                                    <div class="card-body">
                                        <h6 class="card-title fw-bold h_39 text-truncate">${item.title}</h6>
                                        <a class="icon-link text-black d-flex justify-content-between" href="#">
                                            ${item.description}
                                        </a>
                                    </div>
                                </div>
                            </div>
                        </c:forEach>
                        <!--리스트 부분-->
                    </div>


                    <div class="d-flex justify-content-between mt-5 mb-3">
                        <h4 id="contentsmov" class="fw-bold">
                            콘텐츠
                        </h4>
                        <a href="">
                            <small>더보기</small>
                        </a>
                    </div>
                    <div class="row g-3">
                        <!--리스트 부분-->
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img2.jpg" class="card-img-top" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">반도체 공정의 모든 것 - 삼성전자 엔지니어가 설명하는 실무</h6>
                                    <p class="card-text">테크 인사이드</p>
                                    <a class="icon-link text-black d-flex justify-content-between" href="#">
                                        1.2M 조회수
                                        <span class="text-gray-500">3일 전</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img2.jpg" class="card-img-top" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">반도체 공정의 모든 것 - 삼성전자 엔지니어가 설명하는 실무</h6>
                                    <p class="card-text">테크 인사이드</p>
                                    <a class="icon-link text-black d-flex justify-content-between" href="#">
                                        1.2M 조회수
                                        <span class="text-gray-500">3일 전</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img2.jpg" class="card-img-top" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">반도체 공정의 모든 것 - 삼성전자 엔지니어가 설명하는 실무</h6>
                                    <p class="card-text">테크 인사이드</p>
                                    <a class="icon-link text-black d-flex justify-content-between" href="#">
                                        1.2M 조회수
                                        <span class="text-gray-500">3일 전</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img2.jpg" class="card-img-top" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">반도체 공정의 모든 것 - 삼성전자 엔지니어가 설명하는 실무</h6>
                                    <p class="card-text">테크 인사이드</p>
                                    <a class="icon-link text-black d-flex justify-content-between" href="#">
                                        1.2M 조회수
                                        <span class="text-gray-500">3일 전</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <!--리스트 부분-->
                    </div>

                    <div class="d-flex justify-content-between mt-5 mb-3">
                        <h4 id="continue" class="fw-bold">
                            계속 학습하기
                        </h4>
                        <a href="">
                            <small>더보기</small>
                        </a>
                    </div>
                    <div class="row g-3">
                        <!--리스트 부분-->
                        <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/img3.jpg" class="card-img-top h_300" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">반도체 공정의 모든 것 - 삼성전자 엔지니어가 설명하는 실무</h6>
                                    <p class="card-text">김교수</p>
                                    <!--progressbar-->
                                    <div class="d-flex justify-content-between">
                                        <div>진행율</div>
                                        <div>25%</div>
                                    </div>
                                    <div class="progress h_10" role="progressbar" aria-label="진도율" aria-valuenow="25" aria-valuemin="0" aria-valuemax="100">
                                        <div class="progress-bar" style="width:25%"></div>
                                    </div>
                                    <!--progressbar-->
                                    <a href="#" class="btn btn-outline-secondary w-100 mt-3" title="계속 학습하기">계속 학습하기</a>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/image2.png" class="card-img-top h_300" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">반도체 공정의 모든 것 - 삼성전자 엔지니어가 설명하는 실무</h6>
                                    <p class="card-text">김교수</p>
                                    <!--progressbar-->
                                    <div class="d-flex justify-content-between">
                                        <div>진행율</div>
                                        <div>45%</div>
                                    </div>
                                    <div class="progress h_10" role="progressbar" aria-label="진도율" aria-valuenow="45" aria-valuemin="0" aria-valuemax="100">
                                        <div class="progress-bar" style="width:45%"></div>
                                    </div>
                                    <!--progressbar-->
                                    <a href="#" class="btn btn-outline-secondary w-100 mt-3" title="계속 학습하기">계속 학습하기</a>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                            <div class="card rounded-3 shadow-sm shadow-sm-hover">
                                <img src="/images/image4.png" class="card-img-top h_300" alt="반도체 공정 기초">
                                <div class="card-body">
                                    <h6 class="card-title fw-bold">반도체 공정의 모든 것 - 삼성전자 엔지니어가 설명하는 실무</h6>
                                    <p class="card-text">김교수</p>
                                    <!--progressbar-->
                                    <div class="d-flex justify-content-between">
                                        <div>진행율</div>
                                        <div>75%</div>
                                    </div>
                                    <div class="progress h_10" role="progressbar" aria-label="진도율" aria-valuenow="75" aria-valuemin="0" aria-valuemax="100">
                                        <div class="progress-bar" style="width:75%"></div>
                                    </div>
                                    <!--progressbar-->
                                    <a href="#" class="btn btn-outline-secondary w-100 mt-3" title="계속 학습하기">계속 학습하기</a>
                                </div>
                            </div>
                        </div>
                        <!--리스트 부분-->
                    </div>


                    <div class="d-flex justify-content-between mt-5 mb-3">
                        <h4 id="boardfile" class="fw-bold">
                            연구보고서
                        </h4>
                        <a href="#none">
                            <small>더보기</small>
                        </a>
                    </div>
                    <div class="row g-3">
                        <img src="/images/imsiimg.png" alt="연구보고서">
                    </div>

                </div>
            </div>
        </section>

        <!-- 관심사 설문 오버레이 (화면정의서 9~12p 기반 1차 버전) -->
        <div id="studentInterestOverlay" class="position-fixed top-0 start-0 w-100 h-100 bg-dark bg-opacity-50 d-none" style="z-index: 1050;">
            <div class="d-flex justify-content-center align-items-center h-100">
                <div class="bg-white rounded-3 shadow-lg p-4 p-sm-5" style="max-width: 720px; width: 100%; max-height: 90vh; overflow:auto;">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h4 class="fw-bold mb-0">나의 관심사 설정</h4>
                        <button type="button" class="btn btn-sm btn-outline-secondary" id="btnInterestClose">
                            <i class="bi bi-x-lg"></i>
                        </button>
                    </div>
                    <div class="mb-2">
                        <small class="text-muted">
                            <span id="interestStepIndicator">1</span> / 4 단계
                        </small>
                    </div>

                    <!-- 1단계: 관심 있는 분야 선택 (NCS 24개 대분류) -->
                    <div class="interest-step" data-step="1">
                        <h5 class="fw-semibold mb-3">관심 있는 분야를 선택해 주세요.</h5>
                        <p class="text-muted small mb-3">여러 개를 선택할 수 있습니다.</p>
                        <div id="interestNcsList" class="row g-2">
                            <!-- NCS 대분류 24개는 스크립트에서 defaultNcsMaster로 렌더링 -->
                        </div>
                    </div>

                    <!-- 2단계: 목표 진로경로 선택 -->
                    <div class="interest-step d-none" data-step="2">
                        <h5 class="fw-semibold mb-3">목표 진로 경로를 선택해 주세요.</h5>
                        <div class="row g-2">
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-career-item" data-id="domestic_job">
                                    국내취업
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-career-item" data-id="overseas_job">
                                    해외취업
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-career-item" data-id="startup">
                                    창업
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-career-item" data-id="grad">
                                    대학원진학
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-career-item" data-id="freelancer">
                                    프리랜서
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-career-item" data-id="etc">
                                    기타
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 3단계: 목표 기업유형 선택 -->
                    <div class="interest-step d-none" data-step="3">
                        <h5 class="fw-semibold mb-3">목표하는 기업유형을 선택해 주세요.</h5>
                        <div class="row g-2">
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-company-item" data-id="large">
                                    대기업
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-company-item" data-id="mid">
                                    중견기업
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-company-item" data-id="small">
                                    중소기업
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-company-item" data-id="public">
                                    공공기관·공기업
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-company-item" data-id="foreign">
                                    외국계 기업
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-company-item" data-id="startup_company">
                                    스타트업
                                </button>
                            </div>
                            <div class="col-6 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-company-item" data-id="etc_company">
                                    기타
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 4단계: 보유/관심 스킬 선택 -->
                    <div class="interest-step d-none" data-step="4">
                        <h5 class="fw-semibold mb-3">보유하거나 관심 있는 스킬을 선택해 주세요.</h5>
                        <p class="text-muted small mb-3">복수 선택 가능, 예시는 학과 공통 스킬입니다.</p>
                        <div class="row g-2">
                            <div class="col-6 col-sm-4 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-skill-item" data-id="python">
                                    Python
                                </button>
                            </div>
                            <div class="col-6 col-sm-4 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-skill-item" data-id="cad">
                                    CAD
                                </button>
                            </div>
                            <div class="col-6 col-sm-4 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-skill-item" data-id="iot">
                                    IoT
                                </button>
                            </div>
                            <div class="col-6 col-sm-4 mb-2">
                                <button type="button" class="btn w-100 btn-outline-primary interest-skill-item" data-id="welding">
                                    용접
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 하단 버튼 -->
                    <div class="d-flex justify-content-between align-items-center mt-4">
                        <button type="button" class="btn btn-outline-secondary" id="btnInterestPrev">
                            이전
                        </button>
                        <button type="button" class="btn btn-primary" id="btnInterestNext">
                            다음
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 나의 관심사 요약 오버레이 (화면정의서 14p 기반) -->
        <div id="studentInterestSummaryOverlay" class="position-fixed top-0 start-0 w-100 h-100 bg-dark bg-opacity-50 d-none" style="z-index: 1051;">
            <div class="d-flex justify-content-center align-items-center h-100">
                <div class="bg-white rounded-3 shadow-lg p-4 p-sm-5" style="max-width: 640px; width: 100%; max-height: 80vh; overflow:auto;">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h4 class="fw-bold mb-0">나의 관심사</h4>
                        <button type="button" class="btn btn-sm btn-outline-secondary" id="btnInterestSummaryClose">
                            <i class="bi bi-x-lg"></i>
                        </button>
                    </div>
                    <div class="mb-3">
                        <p class="mb-2">
                            <span class="text-muted small">관심 분야</span><br>
                            <span id="summaryNcs" class="fw-semibold"></span>
                        </p>
                        <p class="mb-2">
                            <span class="text-muted small">목표 진로 경로</span><br>
                            <span id="summaryCareer" class="fw-semibold"></span>
                        </p>
                        <p class="mb-2">
                            <span class="text-muted small">관심 기업 유형</span><br>
                            <span id="summaryCompany" class="fw-semibold"></span>
                        </p>
                        <p class="mb-2">
                            <span class="text-muted small">관심 스킬</span><br>
                            <span id="summarySkills" class="fw-semibold"></span>
                        </p>
                    </div>
                    <div class="d-flex justify-content-end gap-2 mt-3">
                        <button type="button" class="btn btn-outline-secondary" id="btnInterestSummaryClose2">
                            닫기
                        </button>
                        <button type="button" class="btn btn-primary" id="btnInterestReopenSurvey">
                            관심사 다시 설정하기
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <script type="text/javascript">
            (function() {
                var currentStep = 1;
                var maxStep = 4;
                var interestMaster = [];
                var interestMasterMap = {};
                var currentInterest = null;
                var hasInterest = false;

                // NCS 국가직무능력표준 24개 대분류 (https://www.ncs.go.kr 기준)
                var defaultNcsMaster = [
                    { id: "01", title: "사업관리" },
                    { id: "02", title: "경영·회계·사무" },
                    { id: "03", title: "금융·보험" },
                    { id: "04", title: "교육·자연·사회과학" },
                    { id: "05", title: "법률·경찰·소방·교도·국방" },
                    { id: "06", title: "보건·의료" },
                    { id: "07", title: "사회복지·종교" },
                    { id: "08", title: "문화·예술·디자인·방송" },
                    { id: "09", title: "운전·운송" },
                    { id: "10", title: "영업·판매" },
                    { id: "11", title: "경비·청소" },
                    { id: "12", title: "이용·숙박·여행·오락·스포츠" },
                    { id: "13", title: "음식서비스" },
                    { id: "14", title: "건설" },
                    { id: "15", title: "기계" },
                    { id: "16", title: "재료" },
                    { id: "17", title: "화학" },
                    { id: "18", title: "섬유·의복" },
                    { id: "19", title: "전기·전자" },
                    { id: "20", title: "정보통신" },
                    { id: "21", title: "식품가공" },
                    { id: "22", title: "인쇄·목재·가구·공예" },
                    { id: "23", title: "환경·에너지·안전" },
                    { id: "24", title: "농림어업" }
                ];

                var careerLabels = {
                    "domestic_job": "국내취업",
                    "overseas_job": "해외취업",
                    "startup": "창업",
                    "grad": "대학원진학",
                    "freelancer": "프리랜서",
                    "etc": "기타"
                };
                var companyLabels = {
                    "large": "대기업",
                    "mid": "중견기업",
                    "small": "중소기업",
                    "startup_company": "스타트업",
                    "public": "공공기관",
                    "foreign": "외국계기업",
                    "etc_company": "기타"
                };

                function parseCsv(str) {
                    if (!str) {
                        return [];
                    }
                    return String(str).split(',').map(function (s) {
                        return s.trim();
                    }).filter(function (s) {
                        return s.length > 0;
                    });
                }

                function joinLabels(list) {
                    if (!list || !list.length) {
                        return "-";
                    }
                    return list.join(', ');
                }

                function updateStepView() {
                    var steps = document.querySelectorAll('.interest-step');
                    steps.forEach(function (el) {
                        var step = parseInt(el.getAttribute('data-step'), 10);
                        if (step === currentStep) {
                            el.classList.remove('d-none');
                        } else {
                            el.classList.add('d-none');
                        }
                    });
                    var indicator = document.getElementById('interestStepIndicator');
                    if (indicator) {
                        indicator.textContent = String(currentStep);
                    }
                    var prevBtn = document.getElementById('btnInterestPrev');
                    var nextBtn = document.getElementById('btnInterestNext');
                    if (prevBtn) {
                        prevBtn.disabled = currentStep === 1;
                    }
                    if (nextBtn) {
                        nextBtn.textContent = (currentStep === maxStep) ? '완료' : '다음';
                    }
                }

                function toggleSelected(className, target, singleSelect) {
                    if (!target || !target.classList.contains(className)) {
                        return;
                    }
                    if (singleSelect) {
                        var items = document.querySelectorAll('.' + className);
                        items.forEach(function (el) {
                            el.classList.add('btn-outline-primary');
                            el.classList.remove('btn-primary');
                        });
                    }
                    target.classList.toggle('btn-outline-primary');
                    target.classList.toggle('btn-primary');
                }

                function openSurvey(resetStep) {
                    var overlay = document.getElementById('studentInterestOverlay');
                    if (!overlay) {
                        return;
                    }
                    if (resetStep) {
                        currentStep = 1;
                    }
                    updateStepView();
                    overlay.classList.remove('d-none');
                }

                function closeSurvey() {
                    var overlay = document.getElementById('studentInterestOverlay');
                    if (overlay) {
                        overlay.classList.add('d-none');
                    }
                }

                function openSummary() {
                    var overlay = document.getElementById('studentInterestSummaryOverlay');
                    if (!overlay) {
                        openSurvey(true);
                        return;
                    }
                    updateSummaryFromCurrent();
                    overlay.classList.remove('d-none');
                }

                function closeSummary() {
                    var overlay = document.getElementById('studentInterestSummaryOverlay');
                    if (overlay) {
                        overlay.classList.add('d-none');
                    }
                }

                function populateInterestMaster(list) {
                    interestMaster = list || [];
                    interestMasterMap = {};
                    var container = document.getElementById('interestNcsList');
                    if (!container || !list || !list.length) {
                        return;
                    }
                    container.innerHTML = "";
                    list.forEach(function (item) {
                        var id = String(item.id);
                        interestMasterMap[id] = item.title;
                        var col = document.createElement('div');
                        col.className = 'col-6 col-sm-4 mb-2';
                        var btn = document.createElement('button');
                        btn.type = 'button';
                        btn.className = 'btn w-100 btn-outline-primary interest-ncs-item';
                        btn.setAttribute('data-id', id);
                        btn.textContent = item.title;
                        col.appendChild(btn);
                        container.appendChild(col);
                    });
                }

                function applyInterestToUI() {
                    if (!currentInterest) {
                        return;
                    }
                    // NCS
                    var ncsIds = parseCsv(currentInterest.ncsLargeIds);
                    var ncsButtons = document.querySelectorAll('.interest-ncs-item');
                    ncsButtons.forEach(function (btn) {
                        var id = btn.getAttribute('data-id');
                        if (!id) {
                            return;
                        }
                        if (ncsIds.indexOf(id) !== -1) {
                            btn.classList.remove('btn-outline-primary');
                            btn.classList.add('btn-primary');
                        } else {
                            btn.classList.add('btn-outline-primary');
                            btn.classList.remove('btn-primary');
                        }
                    });

                    // 진로 경로
                    var careerId = currentInterest.careerPath || "";
                    var careerButtons = document.querySelectorAll('.interest-career-item');
                    careerButtons.forEach(function (btn) {
                        var id = btn.getAttribute('data-id') || "";
                        if (id === careerId && careerId) {
                            btn.classList.remove('btn-outline-primary');
                            btn.classList.add('btn-primary');
                        } else {
                            btn.classList.add('btn-outline-primary');
                            btn.classList.remove('btn-primary');
                        }
                    });

                    // 기업 유형
                    var companyId = currentInterest.companyType || "";
                    var companyButtons = document.querySelectorAll('.interest-company-item');
                    companyButtons.forEach(function (btn) {
                        var id = btn.getAttribute('data-id') || "";
                        if (id === companyId && companyId) {
                            btn.classList.remove('btn-outline-primary');
                            btn.classList.add('btn-primary');
                        } else {
                            btn.classList.add('btn-outline-primary');
                            btn.classList.remove('btn-primary');
                        }
                    });

                    // 스킬
                    var skillIds = parseCsv(currentInterest.skills);
                    var skillButtons = document.querySelectorAll('.interest-skill-item');
                    skillButtons.forEach(function (btn) {
                        var id = btn.getAttribute('data-id');
                        if (!id) {
                            return;
                        }
                        if (skillIds.indexOf(id) !== -1) {
                            btn.classList.remove('btn-outline-primary');
                            btn.classList.add('btn-primary');
                        } else {
                            btn.classList.add('btn-outline-primary');
                            btn.classList.remove('btn-primary');
                        }
                    });

                    updateSummaryFromCurrent();
                }

                function updateSummaryFromCurrent() {
                    var ncsSpan = document.getElementById('summaryNcs');
                    var careerSpan = document.getElementById('summaryCareer');
                    var companySpan = document.getElementById('summaryCompany');
                    var skillsSpan = document.getElementById('summarySkills');
                    if (!ncsSpan || !careerSpan || !companySpan || !skillsSpan || !currentInterest) {
                        return;
                    }

                    var ncsIds = parseCsv(currentInterest.ncsLargeIds);
                    var ncsTitles = ncsIds.map(function (id) {
                        return interestMasterMap[id] || id;
                    });
                    ncsSpan.textContent = joinLabels(ncsTitles);

                    var careerId = currentInterest.careerPath || "";
                    careerSpan.textContent = careerLabels[careerId] || "-";

                    var companyId = currentInterest.companyType || "";
                    companySpan.textContent = companyLabels[companyId] || "-";

                    var skillIds = parseCsv(currentInterest.skills);
                    var skillTitles = [];
                    var skillButtons = document.querySelectorAll('.interest-skill-item');
                    skillButtons.forEach(function (btn) {
                        var id = btn.getAttribute('data-id');
                        if (id && skillIds.indexOf(id) !== -1) {
                            skillTitles.push(btn.textContent.trim());
                        }
                    });
                    skillsSpan.textContent = joinLabels(skillTitles);
                }

                function collectInterestFromUI() {
                    var ncsButtons = document.querySelectorAll('.interest-ncs-item.btn-primary');
                    var ncsIds = [];
                    ncsButtons.forEach(function (btn) {
                        var id = btn.getAttribute('data-id');
                        if (id) {
                            ncsIds.push(id);
                        }
                    });

                    var careerId = "";
                    var careerButtons = document.querySelectorAll('.interest-career-item');
                    careerButtons.forEach(function (btn) {
                        if (btn.classList.contains('btn-primary')) {
                            careerId = btn.getAttribute('data-id') || "";
                        }
                    });

                    var companyId = "";
                    var companyButtons = document.querySelectorAll('.interest-company-item');
                    companyButtons.forEach(function (btn) {
                        if (btn.classList.contains('btn-primary')) {
                            companyId = btn.getAttribute('data-id') || "";
                        }
                    });

                    var skillButtons = document.querySelectorAll('.interest-skill-item.btn-primary');
                    var skillIds = [];
                    skillButtons.forEach(function (btn) {
                        var id = btn.getAttribute('data-id');
                        if (id) {
                            skillIds.push(id);
                        }
                    });

                    return {
                        ncsLargeIds: ncsIds.join(','),
                        careerPath: careerId,
                        companyType: companyId,
                        skills: skillIds.join(',')
                    };
                }

                function fetchInterestMasterAndStudent() {
                    // 1단계: 관리자에서 설정한 관심사 마스터 먼저 조회
                    fetch('/json/interest/list.do', {
                        method: 'GET',
                        credentials: 'same-origin'
                    }).then(function (res) {
                        return res.json();
                    }).then(function (json) {
                        if (json && json.result === 'success' && Array.isArray(json.data) && json.data.length > 0) {
                            populateInterestMaster(json.data);
                        } else {
                            // 관리자 데이터가 없을 경우에만 NCS 24개 기본값 사용
                            populateInterestMaster(defaultNcsMaster);
                        }
                    }).catch(function () {
                        // 오류 시에도 기본 NCS 24개 사용
                        populateInterestMaster(defaultNcsMaster);
                    });

                    // 2단계: 학생 관심사
                    fetch('/json/interest/get.do', {
                        method: 'GET',
                        credentials: 'same-origin'
                    }).then(function (res) {
                        return res.json();
                    }).then(function (json) {
                        if (json && json.result === 'success' && json.data) {
                            currentInterest = json.data;
                            hasInterest = true;
                            applyInterestToUI();
                        }
                    }).catch(function () {
                        // ignore
                    });
                }

                /**
                 * 추천 영상 섹션에 PLISM 동영상 리스트를 채워 넣는 함수입니다.
                 * /json/move/list.do API를 호출하여 응답 데이터를 기반으로 카드 UI를 생성합니다.
                 */
                function loadRecommendMovieList() {
                    // 추천 영상 카드가 들어갈 컨테이너 DOM 을 찾습니다.
                    var listElement = document.getElementById('recommendMovList');
                    if (!listElement) {
                        return;
                    }

                    // 처음에는 기존에 하드코딩되어 있던 더미 카드를 모두 지웁니다.
                    listElement.innerHTML = '';

                    // 동영상 리스트 조회 API를 호출합니다.
                    fetch('/json/move/list.do', {
                        method: 'GET',
                        credentials: 'same-origin'
                    }).then(function (res) {
                        return res.json();
                    }).then(function (json) {
                        // 응답 구조가 정상인지 확인합니다.
                        if (!json || json.result !== 'success' || !Array.isArray(json.data) || json.data.length === 0) {
                            // 데이터가 없거나 오류인 경우에는 간단한 안내 문구만 표시합니다.
                            listElement.innerHTML = '<p class="text-muted">추천 영상이 아직 준비되지 않았습니다.</p>';
                            return;
                        }

                        // 실제 응답 JSON 구조에 맞게 필드명을 사용할 수 있도록 안전하게 값을 꺼냅니다.
                        json.data.forEach(function (item) {
                            // 제목: 여러 후보 필드 중 존재하는 값을 사용합니다.
                            var title = item.title || item.mov_name || item.subject || '제목 없음';
                            // 썸네일 이미지 URL
                            var thumb = item.thumb || item.thumbnail || item.mov_thumbnail || '/images/img2.jpg';
                            // 강의/채널/교수명
                            var owner = item.teacher || item.professor || item.channel || '';
                            // 조회수 정보
                            var viewText = item.viewcount || item.view_cnt || '';
                            // 업로드/등록일 정보
                            var dateText = item.regdate || item.createdAt || '';
                            // 클릭 시 이동할 링크 (있으면 사용, 없으면 막다른 링크 처리)
                            var link = item.link || item.url || '#';

                            // 부트스트랩 카드 구조를 그대로 맞춰서 DOM 을 생성합니다.
                            var col = document.createElement('div');
                            col.className = 'col-12 col-sm-6 col-md-4 col-lg-3';

                            col.innerHTML =
                                '<div class="card rounded-3 shadow-sm shadow-sm-hover">' +
                                '  <img src="' + thumb + '" class="card-img-top" alt="' + title + '">' +
                                '  <div class="card-body">' +
                                '    <h6 class="card-title fw-bold text-truncate">' + title + '</h6>' +
                                '    <p class="card-text text-truncate">' + (owner || '') + '</p>' +
                                '    <a class="icon-link text-black d-flex justify-content-between" href="' + link + '">' +
                                '      ' + (viewText || '') +
                                '      <span class="text-gray-500">' + (dateText || '') + '</span>' +
                                '    </a>' +
                                '  </div>' +
                                '</div>';

                            listElement.appendChild(col);
                        });
                    }).catch(function () {
                        // 네트워크 오류 등으로 실패한 경우 간단한 오류 메시지를 노출합니다.
                        listElement.innerHTML = '<p class="text-danger">추천 영상을 불러오는 중 오류가 발생했습니다.</p>';
                    });
                }

                document.addEventListener('DOMContentLoaded', function () {
                    var openBtn = document.getElementById('btnMyInterest');
                    var surveyOverlay = document.getElementById('studentInterestOverlay');
                    var surveyCloseBtn = document.getElementById('btnInterestClose');
                    var prevBtn = document.getElementById('btnInterestPrev');
                    var nextBtn = document.getElementById('btnInterestNext');
                    var summaryOverlay = document.getElementById('studentInterestSummaryOverlay');
                    var summaryCloseBtn = document.getElementById('btnInterestSummaryClose');
                    var summaryCloseBtn2 = document.getElementById('btnInterestSummaryClose2');
                    var reopenSurveyBtn = document.getElementById('btnInterestReopenSurvey');

                    if (openBtn) {
                        openBtn.addEventListener('click', function () {
                            if (hasInterest && currentInterest) {
                                openSummary();
                            } else {
                                openSurvey(true);
                            }
                        });
                    }
                    if (surveyCloseBtn && surveyOverlay) {
                        surveyCloseBtn.addEventListener('click', function () {
                            closeSurvey();
                        });
                    }
                    if (summaryCloseBtn && summaryOverlay) {
                        summaryCloseBtn.addEventListener('click', function () {
                            closeSummary();
                        });
                    }
                    if (summaryCloseBtn2 && summaryOverlay) {
                        summaryCloseBtn2.addEventListener('click', function () {
                            closeSummary();
                        });
                    }
                    if (reopenSurveyBtn) {
                        reopenSurveyBtn.addEventListener('click', function () {
                            closeSummary();
                            openSurvey(false);
                        });
                    }

                    if (prevBtn) {
                        prevBtn.addEventListener('click', function () {
                            if (currentStep > 1) {
                                currentStep--;
                                updateStepView();
                            }
                        });
                    }
                    if (nextBtn && surveyOverlay) {
                        nextBtn.addEventListener('click', function () {
                            if (currentStep < maxStep) {
                                currentStep++;
                                updateStepView();
                            } else {
                                var payload = collectInterestFromUI();
                                var params = new URLSearchParams();
                                params.append('ncsLargeIds', payload.ncsLargeIds);
                                params.append('careerPath', payload.careerPath);
                                params.append('companyType', payload.companyType);
                                params.append('skills', payload.skills);

                                fetch('/json/interest/save.do', {
                                    method: 'POST',
                                    headers: {
                                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                                    },
                                    credentials: 'same-origin',
                                    body: params.toString()
                                }).then(function (res) {
                                    return res.json();
                                }).then(function (json) {
                                    if (json && json.result === 'success') {
                                        currentInterest = payload;
                                        hasInterest = true;
                                        updateSummaryFromCurrent();
                                    }
                                    closeSurvey();
                                }).catch(function () {
                                    closeSurvey();
                                });
                            }
                        });
                    }

                    document.addEventListener('click', function (e) {
                        if (e.target.classList.contains('interest-ncs-item')) {
                            toggleSelected('interest-ncs-item', e.target, false);
                        }
                        if (e.target.classList.contains('interest-career-item')) {
                            toggleSelected('interest-career-item', e.target, true);
                        }
                        if (e.target.classList.contains('interest-company-item')) {
                            toggleSelected('interest-company-item', e.target, true);
                        }
                        if (e.target.classList.contains('interest-skill-item')) {
                            toggleSelected('interest-skill-item', e.target, false);
                        }
                    });

                    updateStepView();
                    fetchInterestMasterAndStudent();

                    // 메인 화면 진입 시 추천 영상 리스트를 함께 불러옵니다.
                    loadRecommendMovieList();
                });
            })();
        </script>
    </div>
<%@ include file="../layout/bottom.jsp" %>
