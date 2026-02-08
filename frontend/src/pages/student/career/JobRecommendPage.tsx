// pages/student/career/JobRecommendPage.tsx — STD-C01: 맞춤 공고 추천
import { useState, useMemo } from 'react';
import {
  Briefcase, MapPin, Building2, Clock, Filter,
  ChevronRight, ChevronLeft, Heart, DollarSign,
  X, ExternalLink, Tag, Calendar, CheckCircle, ArrowUpDown,
} from 'lucide-react';
import { useTranslation } from '@/i18n';

// --- Mock Data ---
interface JobPosting {
  id: number;
  company: string;
  title: string;
  location: string;
  region: string;
  salary: string;
  salaryMin: number;
  companySize: '대기업' | '중견기업' | '중소기업' | '공기업' | '스타트업';
  matchScore: number;
  matchedTags: string[];
  deadline: string;
  dDay: number;
  logoColor: string;
  description: string;
  benefits: string[];
  requirements: string[];
  scrapped: boolean;
}

const mockJobs: JobPosting[] = [
  { id: 1, company: '삼성SDS', title: '신입 백엔드 개발자 (Java/Spring)', location: '서울 송파구', region: '서울', salary: '4,500~5,500만원', salaryMin: 4500, companySize: '대기업', matchScore: 95, matchedTags: ['Java', 'Spring Boot', 'SQL', '정보처리기사'], deadline: '2026-02-28', dDay: 20, logoColor: 'from-blue-500 to-blue-700', description: 'MSA 기반 엔터프라이즈 솔루션 개발', benefits: ['4대보험', '성과급', '자기개발비'], requirements: ['Java 기본 역량', 'Spring Boot 경험', 'RDBMS 이해'], scrapped: true },
  { id: 2, company: 'LG CNS', title: '풀스택 개발자 (React + Java)', location: '서울 마포구', region: '서울', salary: '4,200~5,200만원', salaryMin: 4200, companySize: '대기업', matchScore: 91, matchedTags: ['Java', 'React', 'Spring Boot', 'SQL'], deadline: '2026-03-05', dDay: 25, logoColor: 'from-red-500 to-pink-600', description: 'DX 플랫폼 프론트엔드/백엔드 개발', benefits: ['4대보험', '유연근무', '교육지원'], requirements: ['React 경험', 'Java/Spring 역량', 'REST API 설계'], scrapped: false },
  { id: 3, company: '카카오', title: '서버 개발자 (Kotlin/Spring)', location: '경기 판교', region: '경기', salary: '5,000~6,500만원', salaryMin: 5000, companySize: '대기업', matchScore: 85, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Git'], deadline: '2026-02-20', dDay: 12, logoColor: 'from-yellow-400 to-yellow-600', description: '카카오 서비스 백엔드 시스템 개발', benefits: ['스톡옵션', '무제한휴가', '식비지원'], requirements: ['Kotlin 또는 Java 역량', 'MSA 아키텍처 이해', '대규모 트래픽 처리'], scrapped: false },
  { id: 4, company: '쿠팡', title: '데이터 엔지니어 (Python)', location: '서울 송파구', region: '서울', salary: '4,800~6,000만원', salaryMin: 4800, companySize: '대기업', matchScore: 82, matchedTags: ['Python', 'SQL', '데이터분석', 'SQLD'], deadline: '2026-03-10', dDay: 30, logoColor: 'from-green-500 to-emerald-600', description: '대규모 데이터 파이프라인 구축 및 운영', benefits: ['RSU', '통근버스', '중식제공'], requirements: ['Python 역량', 'SQL 활용', '데이터 파이프라인 이해'], scrapped: true },
  { id: 5, company: '토스', title: 'Backend Engineer', location: '서울 강남구', region: '서울', salary: '5,000~7,000만원', salaryMin: 5000, companySize: '중견기업', matchScore: 78, matchedTags: ['Java', 'Spring Boot', 'Git'], deadline: '2026-03-15', dDay: 35, logoColor: 'from-blue-600 to-indigo-600', description: '금융 서비스 핵심 시스템 개발', benefits: ['자율출퇴근', '최신장비', '4대보험'], requirements: ['Java/Kotlin 역량', '금융 도메인 관심', '테스트 코드 작성'], scrapped: false },
  { id: 6, company: '우아한형제들', title: '주니어 백엔드 개발자', location: '서울 송파구', region: '서울', salary: '4,000~5,000만원', salaryMin: 4000, companySize: '중견기업', matchScore: 74, matchedTags: ['Java', 'Spring Boot', 'SQL'], deadline: '2026-02-25', dDay: 17, logoColor: 'from-sky-400 to-cyan-600', description: '배민 주문/결제 시스템 개발', benefits: ['재택근무', '자기개발비', '중식제공'], requirements: ['Java 기초', 'Spring Boot 경험', '협업 도구 활용'], scrapped: false },
  { id: 7, company: '데이원컴퍼니', title: 'AI/ML 엔지니어', location: '서울 강남구', region: '서울', salary: '3,800~4,800만원', salaryMin: 3800, companySize: '스타트업', matchScore: 68, matchedTags: ['Python', '머신러닝', '데이터분석'], deadline: '2026-03-01', dDay: 21, logoColor: 'from-purple-500 to-violet-600', description: 'AI 기반 교육 플랫폼 개발', benefits: ['스톡옵션', '원격근무', '도서비'], requirements: ['Python/ML 역량', 'TensorFlow 또는 PyTorch', '논문 구현 경험'], scrapped: false },
  { id: 8, company: '메가존클라우드', title: '클라우드 엔지니어', location: '서울 강남구', region: '서울', salary: '3,500~4,500만원', salaryMin: 3500, companySize: '중견기업', matchScore: 62, matchedTags: ['클라우드', 'Linux', 'Docker'], deadline: '2026-03-20', dDay: 40, logoColor: 'from-orange-500 to-amber-600', description: 'AWS/GCP 기반 클라우드 인프라 관리', benefits: ['자격증지원', '교육비', '4대보험'], requirements: ['AWS/GCP 경험', 'Linux 기초', 'Docker/K8s 이해'], scrapped: false },
  // 추가 데이터 (20건 이상)
  { id: 9, company: 'SK텔레콤', title: 'AI 서비스 개발자', location: '서울 중구', region: '서울', salary: '4,800~5,800만원', salaryMin: 4800, companySize: '대기업', matchScore: 88, matchedTags: ['Python', 'AI', 'Spring Boot', 'SQL'], deadline: '2026-03-08', dDay: 28, logoColor: 'from-red-600 to-red-800', description: 'AI 기반 통신 서비스 개발 및 운영', benefits: ['4대보험', '성과급', '학자금'], requirements: ['AI/ML 기초', 'Python 역량', 'REST API 설계'], scrapped: false },
  { id: 10, company: '현대오토에버', title: '소프트웨어 엔지니어', location: '경기 의왕시', region: '경기', salary: '4,000~5,000만원', salaryMin: 4000, companySize: '대기업', matchScore: 80, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Git'], deadline: '2026-03-12', dDay: 32, logoColor: 'from-teal-500 to-teal-700', description: '스마트팩토리 소프트웨어 개발', benefits: ['4대보험', '통근버스', '자기개발비'], requirements: ['Java 역량', 'Spring 프레임워크', '임베디드 관심'], scrapped: false },
  { id: 11, company: '네이버', title: 'Search Platform Engineer', location: '경기 성남시', region: '경기', salary: '5,500~7,000만원', salaryMin: 5500, companySize: '대기업', matchScore: 92, matchedTags: ['Java', 'Spring Boot', 'Elasticsearch', 'Git'], deadline: '2026-02-22', dDay: 14, logoColor: 'from-green-600 to-green-800', description: '네이버 검색 플랫폼 핵심 시스템 개발', benefits: ['스톡옵션', '유연근무', '식비지원'], requirements: ['Java/Kotlin 역량', '대규모 시스템 경험', '검색 엔진 이해'], scrapped: true },
  { id: 12, company: '크래프톤', title: '게임 서버 개발자', location: '서울 강남구', region: '서울', salary: '5,000~6,500만원', salaryMin: 5000, companySize: '대기업', matchScore: 72, matchedTags: ['C++', 'Java', 'Git', 'Linux'], deadline: '2026-03-18', dDay: 38, logoColor: 'from-gray-700 to-gray-900', description: 'PUBG 게임 서버 개발', benefits: ['게임비', 'RSU', '식비지원'], requirements: ['C++ 또는 Java 역량', '네트워크 프로그래밍', '멀티스레딩 이해'], scrapped: false },
  { id: 13, company: '뱅크샐러드', title: '프론트엔드 개발자', location: '서울 강남구', region: '서울', salary: '4,000~5,500만원', salaryMin: 4000, companySize: '스타트업', matchScore: 76, matchedTags: ['React', 'TypeScript', 'Git'], deadline: '2026-02-26', dDay: 18, logoColor: 'from-emerald-500 to-teal-600', description: '금융 데이터 시각화 프론트엔드 개발', benefits: ['스톡옵션', '자율출퇴근', '도서비'], requirements: ['React 역량', 'TypeScript 경험', '금융 관심'], scrapped: false },
  { id: 14, company: '야놀자', title: '백엔드 개발자', location: '서울 강남구', region: '서울', salary: '4,200~5,200만원', salaryMin: 4200, companySize: '중견기업', matchScore: 70, matchedTags: ['Java', 'Spring Boot', 'AWS'], deadline: '2026-03-02', dDay: 22, logoColor: 'from-rose-500 to-pink-600', description: '여행/숙박 플랫폼 백엔드 개발', benefits: ['재택근무', '호텔할인', '4대보험'], requirements: ['Java/Spring 역량', 'AWS 경험', 'MSA 이해'], scrapped: false },
  { id: 15, company: '한화시스템', title: '시스템 엔지니어', location: '대전 유성구', region: '대전', salary: '3,800~4,800만원', salaryMin: 3800, companySize: '대기업', matchScore: 65, matchedTags: ['Java', 'Linux', 'SQL', 'Network'], deadline: '2026-03-25', dDay: 45, logoColor: 'from-orange-600 to-orange-800', description: '방산 시스템 소프트웨어 개발', benefits: ['4대보험', '성과급', '통근버스'], requirements: ['Java 역량', 'Linux 운영', '보안 기초'], scrapped: false },
  { id: 16, company: '당근', title: '백엔드 개발자 (Go)', location: '서울 서초구', region: '서울', salary: '4,500~6,000만원', salaryMin: 4500, companySize: '중견기업', matchScore: 67, matchedTags: ['Go', 'Docker', 'Kubernetes', 'Git'], deadline: '2026-03-06', dDay: 26, logoColor: 'from-orange-400 to-orange-600', description: '당근마켓 중고거래 서비스 개발', benefits: ['원격근무', '장비지원', '식비지원'], requirements: ['Go 언어 역량', '컨테이너 기술', '분산 시스템 이해'], scrapped: false },
  { id: 17, company: '인천AI센터', title: 'AI 연구원', location: '인천 연수구', region: '인천', salary: '3,500~4,500만원', salaryMin: 3500, companySize: '중소기업', matchScore: 73, matchedTags: ['Python', 'AI', '머신러닝', '데이터분석'], deadline: '2026-03-15', dDay: 35, logoColor: 'from-indigo-500 to-indigo-700', description: 'AI 기반 스마트시티 연구 개발', benefits: ['4대보험', '연구비', '학회참가'], requirements: ['Python/ML 역량', '논문 작성 경험', '데이터 분석'], scrapped: false },
  { id: 18, company: '부산IT협회', title: '웹 개발자', location: '부산 해운대구', region: '부산', salary: '3,200~4,000만원', salaryMin: 3200, companySize: '중소기업', matchScore: 60, matchedTags: ['Java', 'Spring Boot', 'React'], deadline: '2026-03-20', dDay: 40, logoColor: 'from-cyan-500 to-blue-600', description: '지역 공공 플랫폼 개발', benefits: ['4대보험', '교육비', '유연근무'], requirements: ['Java/Spring 기초', 'React 경험', '공공사업 관심'], scrapped: false },
  { id: 19, company: '마켓컬리', title: '물류 시스템 개발자', location: '경기 김포시', region: '경기', salary: '4,000~5,000만원', salaryMin: 4000, companySize: '중견기업', matchScore: 71, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Redis'], deadline: '2026-02-27', dDay: 19, logoColor: 'from-purple-600 to-purple-800', description: '새벽배송 물류 시스템 개발', benefits: ['신선식품', '재택근무', '4대보험'], requirements: ['Java/Spring 역량', 'Redis 경험', '물류 도메인 관심'], scrapped: false },
  { id: 20, company: '리디', title: '콘텐츠 플랫폼 개발자', location: '서울 강남구', region: '서울', salary: '3,800~4,800만원', salaryMin: 3800, companySize: '스타트업', matchScore: 69, matchedTags: ['React', 'TypeScript', 'Node.js'], deadline: '2026-03-08', dDay: 28, logoColor: 'from-violet-500 to-purple-600', description: '전자책/웹툰 콘텐츠 플랫폼 개발', benefits: ['도서무제한', '자율출퇴근', '간식비'], requirements: ['React/TypeScript', 'Node.js 경험', 'RESTful API'], scrapped: false },
  { id: 21, company: '센드버드', title: 'Senior Backend Engineer', location: '서울 강남구', region: '서울', salary: '5,500~8,000만원', salaryMin: 5500, companySize: '스타트업', matchScore: 83, matchedTags: ['Java', 'Kotlin', 'AWS', 'Docker'], deadline: '2026-03-10', dDay: 30, logoColor: 'from-violet-600 to-indigo-700', description: '글로벌 채팅 API 플랫폼 개발', benefits: ['RSU', '글로벌출장', '장비지원'], requirements: ['Java/Kotlin 역량', '글로벌 서비스 경험', 'AWS 인프라'], scrapped: false },
  { id: 22, company: '대전테크노파크', title: 'IoT 개발자', location: '대전 유성구', region: '대전', salary: '3,200~4,000만원', salaryMin: 3200, companySize: '중소기업', matchScore: 55, matchedTags: ['C', 'Python', 'Linux', 'IoT'], deadline: '2026-03-30', dDay: 50, logoColor: 'from-lime-500 to-green-600', description: 'IoT 센서 기반 데이터 수집 시스템', benefits: ['4대보험', '연구비', '학회참가'], requirements: ['C/Python 역량', '임베디드 이해', 'IoT 프로토콜'], scrapped: false },
  { id: 23, company: '인천로보틱스', title: '로봇 SW 개발자', location: '인천 남동구', region: '인천', salary: '3,500~4,500만원', salaryMin: 3500, companySize: '중소기업', matchScore: 58, matchedTags: ['Python', 'C++', 'ROS', 'Linux'], deadline: '2026-03-22', dDay: 42, logoColor: 'from-gray-500 to-slate-700', description: '산업용 로봇 제어 소프트웨어', benefits: ['4대보험', '성과급', '교육비'], requirements: ['Python/C++ 역량', 'ROS 경험', '로봇 관심'], scrapped: false },
  { id: 24, company: '부산디지털혁신센터', title: '데이터 분석가', location: '부산 부산진구', region: '부산', salary: '3,000~3,800만원', salaryMin: 3000, companySize: '중소기업', matchScore: 64, matchedTags: ['Python', 'SQL', '데이터분석', '시각화'], deadline: '2026-03-18', dDay: 38, logoColor: 'from-sky-500 to-blue-700', description: '공공 데이터 분석 및 시각화', benefits: ['4대보험', '유연근무', '교육비'], requirements: ['Python 데이터분석', 'SQL 활용', '시각화 도구'], scrapped: false },

  // === 추가 데이터 (48건, ID 25~72) ===
  // 대기업
  { id: 25, company: '한화시스템', title: '클라우드 인프라 엔지니어', location: '대전 유성구', region: '대전', salary: '4,000~6,000만원', salaryMin: 4000, companySize: '대기업', matchScore: 84, matchedTags: ['AWS', 'Docker', 'Kubernetes', 'Linux'], deadline: '2026-03-10', dDay: 29, logoColor: 'from-orange-500 to-red-600', description: '방산 및 ICT 사업부 클라우드 인프라 구축', benefits: ['4대보험', '성과급', '통근버스'], requirements: ['AWS 운영 경험', 'Docker/K8s 활용', 'Linux 서버 관리'], scrapped: false },
  { id: 26, company: '롯데정보통신', title: 'Java 백엔드 개발자', location: '서울 금천구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '대기업', matchScore: 79, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Git'], deadline: '2026-03-15', dDay: 34, logoColor: 'from-red-500 to-red-700', description: '유통/물류 시스템 백엔드 개발', benefits: ['4대보험', '자기개발비', '중식제공'], requirements: ['Java/Spring 역량', 'RDBMS 설계', '유통 도메인 관심'], scrapped: false },
  { id: 27, company: '현대오토에버', title: 'DevOps 엔지니어', location: '경기 의왕시', region: '경기', salary: '4,000~6,000만원', salaryMin: 4000, companySize: '대기업', matchScore: 86, matchedTags: ['Docker', 'Kubernetes', 'CI/CD', 'AWS'], deadline: '2026-03-20', dDay: 39, logoColor: 'from-teal-500 to-teal-700', description: '제조 IT 인프라 자동화 및 DevOps 파이프라인 구축', benefits: ['4대보험', '통근버스', '성과급'], requirements: ['CI/CD 파이프라인 구축', 'K8s 운영', '모니터링 도구 활용'], scrapped: false },
  { id: 28, company: 'CJ올리브네트웍스', title: '풀스택 웹 개발자', location: '서울 중구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '대기업', matchScore: 77, matchedTags: ['React', 'Java', 'Spring Boot', 'TypeScript'], deadline: '2026-03-18', dDay: 37, logoColor: 'from-blue-500 to-cyan-600', description: 'CJ그룹 디지털 트랜스포메이션 플랫폼 개발', benefits: ['4대보험', '유연근무', '자기개발비'], requirements: ['React/TypeScript 경험', 'Java/Spring 역량', 'REST API 설계'], scrapped: false },
  { id: 29, company: 'GS리테일', title: '데이터 플랫폼 엔지니어', location: '서울 강남구', region: '서울', salary: '4,000~6,000만원', salaryMin: 4000, companySize: '대기업', matchScore: 81, matchedTags: ['Python', 'SQL', 'Kafka', 'AWS'], deadline: '2026-03-08', dDay: 27, logoColor: 'from-blue-600 to-indigo-700', description: '리테일 빅데이터 플랫폼 구축 및 운영', benefits: ['4대보험', '성과급', '식비지원'], requirements: ['Python 역량', 'Kafka 이해', '데이터 파이프라인 경험'], scrapped: false },
  { id: 30, company: '효성ITX', title: '시스템 통합 개발자', location: '서울 마포구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '대기업', matchScore: 74, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Linux'], deadline: '2026-04-05', dDay: 55, logoColor: 'from-gray-600 to-gray-800', description: 'IT 아웃소싱 및 SI 프로젝트 개발', benefits: ['4대보험', '교육비', '통근버스'], requirements: ['Java/Spring 역량', '시스템 통합 경험', 'SQL 활용'], scrapped: false },
  { id: 31, company: '포스코ICT', title: '스마트팩토리 SW 개발자', location: '경기 성남시', region: '성남', salary: '4,000~6,000만원', salaryMin: 4000, companySize: '대기업', matchScore: 83, matchedTags: ['Java', 'Python', 'SQL', 'Docker'], deadline: '2026-03-25', dDay: 44, logoColor: 'from-blue-700 to-blue-900', description: 'AI 기반 스마트팩토리 솔루션 개발', benefits: ['4대보험', '성과급', '자기개발비'], requirements: ['Java 또는 Python 역량', 'SQL 활용', '제조 IT 관심'], scrapped: false },
  { id: 32, company: '한화시스템', title: '보안 솔루션 개발자', location: '대전 유성구', region: '대전', salary: '4,000~6,000만원', salaryMin: 4000, companySize: '대기업', matchScore: 76, matchedTags: ['Java', '보안', 'Linux', 'Git'], deadline: '2026-04-10', dDay: 60, logoColor: 'from-orange-500 to-red-600', description: '사이버 보안 솔루션 설계 및 개발', benefits: ['4대보험', '성과급', '학자금'], requirements: ['Java 역량', '정보보안 지식', 'Linux 서버 운영'], scrapped: false },
  { id: 33, company: '롯데정보통신', title: 'React 프론트엔드 개발자', location: '서울 금천구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '대기업', matchScore: 80, matchedTags: ['React', 'TypeScript', 'Git', 'CI/CD'], deadline: '2026-03-12', dDay: 31, logoColor: 'from-red-500 to-red-700', description: '그룹 통합 커머스 프론트엔드 개발', benefits: ['4대보험', '유연근무', '중식제공'], requirements: ['React/TypeScript 숙련', 'CI/CD 이해', '웹 성능 최적화'], scrapped: false },

  // 중견기업
  { id: 34, company: '한컴', title: '문서 플랫폼 백엔드 개발자', location: '경기 성남시', region: '성남', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 78, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Redis'], deadline: '2026-03-22', dDay: 41, logoColor: 'from-blue-500 to-blue-700', description: '한컴 오피스 클라우드 백엔드 개발', benefits: ['4대보험', '자기개발비', '유연근무'], requirements: ['Java/Spring 역량', 'Redis 캐시 활용', 'REST API 설계'], scrapped: false },
  { id: 35, company: '이스트소프트', title: 'AI 서비스 개발자', location: '서울 서초구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 82, matchedTags: ['Python', 'Docker', 'Git', 'AWS'], deadline: '2026-03-05', dDay: 24, logoColor: 'from-green-500 to-green-700', description: 'AI 기반 비즈니스 솔루션 서비스 개발', benefits: ['4대보험', '성과급', '교육비'], requirements: ['Python 역량', 'Docker 활용', 'AI/ML 기초 지식'], scrapped: false },
  { id: 36, company: '다우기술', title: '클라우드 서비스 엔지니어', location: '경기 수원시', region: '수원', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 75, matchedTags: ['AWS', 'Linux', 'Docker', 'Kubernetes'], deadline: '2026-03-28', dDay: 47, logoColor: 'from-indigo-500 to-indigo-700', description: '다우 클라우드 서비스 인프라 운영 및 개발', benefits: ['4대보험', '자격증지원', '유연근무'], requirements: ['AWS 인프라 경험', 'Linux 서버 운영', '컨테이너 기술 이해'], scrapped: false },
  { id: 37, company: '티맥스소프트', title: 'WAS 엔진 개발자', location: '경기 성남시', region: '성남', salary: '4,000~6,000만원', salaryMin: 4000, companySize: '중견기업', matchScore: 72, matchedTags: ['Java', 'Linux', 'Git', 'SQL'], deadline: '2026-04-15', dDay: 65, logoColor: 'from-red-600 to-red-800', description: 'Tibero/JEUS 등 미들웨어 엔진 개발', benefits: ['4대보험', '성과급', '통근버스'], requirements: ['Java 심화 역량', 'Linux 시스템 이해', '미들웨어 관심'], scrapped: false },
  { id: 38, company: '안랩', title: '보안 소프트웨어 개발자', location: '경기 성남시', region: '성남', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 85, matchedTags: ['Java', 'Python', '보안', 'Linux'], deadline: '2026-03-01', dDay: 20, logoColor: 'from-green-600 to-emerald-700', description: '안티바이러스 및 엔드포인트 보안 제품 개발', benefits: ['4대보험', '자격증지원', '교육비'], requirements: ['Java 또는 Python 역량', '정보보안 관심', 'Linux 운영'], scrapped: false },
  { id: 39, company: '한글과컴퓨터', title: 'Vue.js 프론트엔드 개발자', location: '경기 성남시', region: '성남', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 73, matchedTags: ['Vue.js', 'TypeScript', 'Git', 'CI/CD'], deadline: '2026-03-30', dDay: 49, logoColor: 'from-blue-500 to-blue-700', description: '한컴 클라우드 오피스 프론트엔드 개발', benefits: ['4대보험', '유연근무', '자기개발비'], requirements: ['Vue.js 경험', 'TypeScript 역량', '프론트엔드 성능 최적화'], scrapped: false },
  { id: 40, company: '시큐아이', title: '네트워크 보안 개발자', location: '경기 수원시', region: '수원', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 71, matchedTags: ['Java', '보안', '네트워크', 'Linux'], deadline: '2026-04-01', dDay: 51, logoColor: 'from-gray-600 to-gray-800', description: '네트워크 방화벽 및 IPS 제품 개발', benefits: ['4대보험', '자격증지원', '성과급'], requirements: ['Java/C 역량', '네트워크 보안 지식', 'Linux 커널 이해'], scrapped: false },
  { id: 41, company: '드림시큐리티', title: '인증 플랫폼 개발자', location: '서울 강남구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 77, matchedTags: ['Java', 'Spring Boot', '보안', 'SQL'], deadline: '2026-03-14', dDay: 33, logoColor: 'from-purple-500 to-purple-700', description: 'PKI 기반 인증/전자서명 솔루션 개발', benefits: ['4대보험', '성과급', '교육비'], requirements: ['Java/Spring 역량', '보안 인증 기술 관심', 'SQL 활용'], scrapped: false },
  { id: 42, company: '핸디소프트', title: '그룹웨어 백엔드 개발자', location: '서울 구로구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 70, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Git'], deadline: '2026-04-05', dDay: 55, logoColor: 'from-cyan-500 to-cyan-700', description: '기업용 그룹웨어 플랫폼 백엔드 개발', benefits: ['4대보험', '유연근무', '교육비'], requirements: ['Java/Spring 역량', '그룹웨어 도메인 관심', 'REST API 개발'], scrapped: false },
  { id: 43, company: '유니포인트', title: '통합커뮤니케이션 개발자', location: '서울 영등포구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 72, matchedTags: ['Java', 'Node.js', 'SQL', 'Git'], deadline: '2026-04-08', dDay: 58, logoColor: 'from-blue-400 to-blue-600', description: 'UCaaS 플랫폼 백엔드 개발', benefits: ['4대보험', '성과급', '자기개발비'], requirements: ['Java 또는 Node.js 역량', 'WebSocket/SIP 이해', 'SQL 활용'], scrapped: false },
  { id: 44, company: '아이티센', title: 'SI 프로젝트 개발자', location: '서울 강남구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 70, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Git'], deadline: '2026-03-20', dDay: 39, logoColor: 'from-orange-400 to-orange-600', description: '금융/공공 SI 프로젝트 수행', benefits: ['4대보험', '프로젝트성과급', '교육비'], requirements: ['Java/Spring 역량', 'SQL 숙련', '커뮤니케이션 능력'], scrapped: false },
  { id: 45, company: '이스트소프트', title: 'Node.js 백엔드 개발자', location: '서울 서초구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 76, matchedTags: ['Node.js', 'TypeScript', 'MongoDB', 'Docker'], deadline: '2026-03-18', dDay: 37, logoColor: 'from-green-500 to-green-700', description: 'AI 챗봇 서비스 백엔드 개발', benefits: ['4대보험', '성과급', '유연근무'], requirements: ['Node.js/TypeScript 역량', 'MongoDB 활용', 'Docker 경험'], scrapped: false },
  { id: 46, company: '다우기술', title: 'React 프론트엔드 개발자', location: '경기 수원시', region: '수원', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중견기업', matchScore: 78, matchedTags: ['React', 'TypeScript', 'Git', 'CI/CD'], deadline: '2026-03-10', dDay: 29, logoColor: 'from-indigo-500 to-indigo-700', description: '메일/메신저 서비스 프론트엔드 개발', benefits: ['4대보험', '유연근무', '자기개발비'], requirements: ['React/TypeScript 숙련', 'CI/CD 파이프라인 이해', '웹 접근성'], scrapped: false },
  { id: 47, company: '안랩', title: 'Threat Intelligence 엔지니어', location: '경기 성남시', region: '성남', salary: '4,000~6,000만원', salaryMin: 4000, companySize: '중견기업', matchScore: 73, matchedTags: ['Python', '보안', 'Linux', 'SQL'], deadline: '2026-04-20', dDay: 70, logoColor: 'from-green-600 to-emerald-700', description: '위협 인텔리전스 데이터 분석 및 자동화', benefits: ['4대보험', '자격증지원', '학회참가'], requirements: ['Python 역량', '사이버 위협 분석 관심', 'Linux 환경 숙련'], scrapped: false },
  { id: 48, company: '티맥스소프트', title: 'DBMS 엔진 개발자', location: '경기 성남시', region: '성남', salary: '5,000~7,000만원', salaryMin: 5000, companySize: '중견기업', matchScore: 71, matchedTags: ['Java', 'SQL', 'Linux', 'Git'], deadline: '2026-04-25', dDay: 75, logoColor: 'from-red-600 to-red-800', description: 'Tibero DBMS 코어 엔진 개발', benefits: ['4대보험', '성과급', '통근버스'], requirements: ['Java 심화 역량', 'RDBMS 내부 구조 이해', 'Linux 시스템 프로그래밍'], scrapped: false },

  // 중소기업
  { id: 49, company: '코드크래프트', title: 'Spring Boot 백엔드 개발자', location: '서울 마포구', region: '서울', salary: '3,000~4,000만원', salaryMin: 3000, companySize: '중소기업', matchScore: 80, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Git'], deadline: '2026-02-28', dDay: 19, logoColor: 'from-violet-500 to-violet-700', description: '자체 SaaS 제품 백엔드 개발', benefits: ['4대보험', '유연근무', '간식비'], requirements: ['Java/Spring Boot 역량', 'JPA 활용', 'Git 협업'], scrapped: false },
  { id: 50, company: '데브원', title: 'React Native 모바일 개발자', location: '서울 강남구', region: '서울', salary: '3,000~4,000만원', salaryMin: 3000, companySize: '중소기업', matchScore: 75, matchedTags: ['React', 'TypeScript', 'Git', 'Node.js'], deadline: '2026-03-05', dDay: 24, logoColor: 'from-pink-500 to-rose-600', description: '모바일 앱 서비스 개발', benefits: ['4대보험', '유연근무', '도서비'], requirements: ['React Native 경험', 'TypeScript 역량', '앱 배포 경험'], scrapped: false },
  { id: 51, company: '클라우드웨이브', title: 'AWS 클라우드 엔지니어', location: '경기 성남시', region: '성남', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중소기업', matchScore: 82, matchedTags: ['AWS', 'Docker', 'Kubernetes', 'Linux'], deadline: '2026-03-15', dDay: 34, logoColor: 'from-sky-500 to-sky-700', description: '클라우드 마이그레이션 및 인프라 컨설팅', benefits: ['4대보험', '자격증지원', '재택근무'], requirements: ['AWS 자격증 보유', 'Docker/K8s 운영', 'IaC 도구 활용'], scrapped: false },
  { id: 52, company: '인사이트랩', title: '데이터 분석 엔지니어', location: '서울 관악구', region: '서울', salary: '3,000~4,000만원', salaryMin: 3000, companySize: '중소기업', matchScore: 78, matchedTags: ['Python', 'SQL', 'MongoDB', 'Git'], deadline: '2026-03-10', dDay: 29, logoColor: 'from-amber-500 to-amber-700', description: '데이터 기반 마케팅 인사이트 분석', benefits: ['4대보험', '유연근무', '교육비'], requirements: ['Python 데이터 분석', 'SQL 숙련', 'MongoDB 경험'], scrapped: false },
  { id: 53, company: '에이아이솔루션', title: 'AI 엔지니어 (NLP)', location: '대전 유성구', region: '대전', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중소기업', matchScore: 85, matchedTags: ['Python', 'Docker', 'Git', 'Linux'], deadline: '2026-03-20', dDay: 39, logoColor: 'from-purple-600 to-purple-800', description: '자연어 처리 기반 AI 솔루션 개발', benefits: ['4대보험', '연구비', '학회참가'], requirements: ['Python ML/NLP 역량', 'Docker 활용', '딥러닝 프레임워크'], scrapped: false },
  { id: 54, company: '테크브리지', title: 'Vue.js 풀스택 개발자', location: '부산 해운대구', region: '부산', salary: '3,000~4,000만원', salaryMin: 3000, companySize: '중소기업', matchScore: 74, matchedTags: ['Vue.js', 'Node.js', 'SQL', 'Git'], deadline: '2026-03-25', dDay: 44, logoColor: 'from-teal-500 to-teal-700', description: '중소기업 ERP 솔루션 개발', benefits: ['4대보험', '유연근무', '교육비'], requirements: ['Vue.js 경험', 'Node.js 역량', 'SQL 활용'], scrapped: false },
  { id: 55, company: '넥스트코딩', title: 'Flutter 앱 개발자', location: '대구 수성구', region: '대구', salary: '3,000~4,000만원', salaryMin: 3000, companySize: '중소기업', matchScore: 72, matchedTags: ['Flutter', 'Git', 'Firebase', 'Docker'], deadline: '2026-04-01', dDay: 51, logoColor: 'from-cyan-500 to-cyan-700', description: '크로스플랫폼 모바일 앱 개발', benefits: ['4대보험', '유연근무', '간식비'], requirements: ['Flutter/Dart 역량', 'Firebase 활용', '앱 배포 경험'], scrapped: false },
  { id: 56, company: '디지털포지', title: '백엔드 개발자 (Python/Django)', location: '광주 서구', region: '광주', salary: '3,000~4,000만원', salaryMin: 3000, companySize: '중소기업', matchScore: 76, matchedTags: ['Python', 'SQL', 'Docker', 'Git'], deadline: '2026-03-18', dDay: 37, logoColor: 'from-lime-500 to-lime-700', description: '공공 웹 서비스 백엔드 개발', benefits: ['4대보험', '유연근무', '교육비'], requirements: ['Python/Django 역량', 'SQL 활용', 'Docker 기초'], scrapped: false },
  { id: 57, company: '스마트코드', title: 'React 프론트엔드 개발자', location: '인천 연수구', region: '인천', salary: '3,000~4,000만원', salaryMin: 3000, companySize: '중소기업', matchScore: 79, matchedTags: ['React', 'TypeScript', 'Git', 'CI/CD'], deadline: '2026-03-08', dDay: 27, logoColor: 'from-blue-400 to-blue-600', description: '스마트시티 관제 시스템 프론트엔드 개발', benefits: ['4대보험', '유연근무', '자기개발비'], requirements: ['React/TypeScript 역량', 'CI/CD 이해', 'UI/UX 감각'], scrapped: false },
  { id: 58, company: '퓨처시스템', title: '보안 솔루션 개발자', location: '경기 수원시', region: '수원', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중소기업', matchScore: 73, matchedTags: ['Java', '보안', 'Linux', 'Git'], deadline: '2026-04-10', dDay: 60, logoColor: 'from-gray-500 to-gray-700', description: '네트워크 보안 장비 소프트웨어 개발', benefits: ['4대보험', '자격증지원', '성과급'], requirements: ['Java/C 역량', '보안 프로토콜 이해', 'Linux 개발 환경'], scrapped: false },
  { id: 59, company: '제니퍼소프트', title: 'APM 모니터링 개발자', location: '경기 성남시', region: '성남', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중소기업', matchScore: 81, matchedTags: ['Java', 'Spring Boot', 'Redis', 'Docker'], deadline: '2026-03-12', dDay: 31, logoColor: 'from-green-400 to-green-600', description: '애플리케이션 성능 모니터링 솔루션 개발', benefits: ['4대보험', '유연근무', '교육비'], requirements: ['Java 역량', 'JVM 내부 이해', 'Redis 활용'], scrapped: false },
  { id: 60, company: '와이즈스톤', title: 'QA 자동화 엔지니어', location: '서울 구로구', region: '서울', salary: '3,000~4,000만원', salaryMin: 3000, companySize: '중소기업', matchScore: 70, matchedTags: ['Python', 'Git', 'CI/CD', 'Docker'], deadline: '2026-04-15', dDay: 65, logoColor: 'from-yellow-500 to-yellow-700', description: 'SW 테스트 자동화 및 QA 솔루션 개발', benefits: ['4대보험', '교육비', '유연근무'], requirements: ['Python 역량', '테스트 자동화 경험', 'CI/CD 파이프라인 이해'], scrapped: false },
  { id: 61, company: '코드크래프트', title: 'TypeScript 풀스택 개발자', location: '서울 마포구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중소기업', matchScore: 83, matchedTags: ['TypeScript', 'React', 'Node.js', 'MongoDB'], deadline: '2026-02-20', dDay: 11, logoColor: 'from-violet-500 to-violet-700', description: 'SaaS 대시보드 풀스택 개발', benefits: ['4대보험', '유연근무', '간식비'], requirements: ['TypeScript 숙련', 'React/Node.js 경험', 'MongoDB 활용'], scrapped: false },
  { id: 62, company: '에이아이솔루션', title: 'MLOps 엔지니어', location: '대전 유성구', region: '대전', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중소기업', matchScore: 87, matchedTags: ['Python', 'Docker', 'Kubernetes', 'AWS'], deadline: '2026-03-02', dDay: 21, logoColor: 'from-purple-600 to-purple-800', description: 'ML 모델 배포 파이프라인 구축', benefits: ['4대보험', '연구비', '재택근무'], requirements: ['Python 역량', 'Docker/K8s 운영', 'MLOps 파이프라인 경험'], scrapped: false },
  { id: 63, company: '디지털포지', title: 'Kafka 데이터 엔지니어', location: '광주 서구', region: '광주', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '중소기업', matchScore: 75, matchedTags: ['Kafka', 'Python', 'SQL', 'Docker'], deadline: '2026-04-20', dDay: 70, logoColor: 'from-lime-500 to-lime-700', description: '실시간 데이터 스트리밍 파이프라인 구축', benefits: ['4대보험', '유연근무', '교육비'], requirements: ['Kafka 운영 경험', 'Python 역량', 'SQL 활용'], scrapped: false },

  // 공기업
  { id: 64, company: '한국전자통신연구원(ETRI)', title: 'AI 연구개발 엔지니어', location: '대전 유성구', region: '대전', salary: '회사 내규', salaryMin: 4000, companySize: '공기업', matchScore: 91, matchedTags: ['Python', 'Docker', 'Linux', 'Git'], deadline: '2026-02-28', dDay: 19, logoColor: 'from-blue-600 to-blue-800', description: '국가 AI 핵심 기술 연구 및 개발', benefits: ['4대보험', '연구비', '학회참가'], requirements: ['Python/ML 역량', '연구 논문 실적', '리눅스 환경 숙련'], scrapped: false },
  { id: 65, company: '정보통신산업진흥원(NIPA)', title: '정보시스템 운영 담당자', location: '대전 유성구', region: '대전', salary: '회사 내규', salaryMin: 3500, companySize: '공기업', matchScore: 74, matchedTags: ['Java', 'SQL', 'Linux', 'Git'], deadline: '2026-03-15', dDay: 34, logoColor: 'from-teal-600 to-teal-800', description: '국가 정보시스템 운영 및 유지보수', benefits: ['4대보험', '교육비', '안정적근무'], requirements: ['Java 역량', 'SQL 활용', 'Linux 서버 운영'], scrapped: false },
  { id: 66, company: '한국과학기술정보연구원(KISTI)', title: '빅데이터 플랫폼 개발자', location: '대전 유성구', region: '대전', salary: '면접 후 결정', salaryMin: 4000, companySize: '공기업', matchScore: 88, matchedTags: ['Python', 'Kafka', 'SQL', 'Docker'], deadline: '2026-03-10', dDay: 29, logoColor: 'from-indigo-600 to-indigo-800', description: '과학기술 빅데이터 분석 플랫폼 구축', benefits: ['4대보험', '연구비', '학회참가'], requirements: ['Python 역량', 'Kafka 이해', '대규모 데이터 처리 경험'], scrapped: false },
  { id: 67, company: '한국인터넷진흥원(KISA)', title: '사이버보안 분석 연구원', location: '서울 송파구', region: '서울', salary: '면접 후 결정', salaryMin: 4000, companySize: '공기업', matchScore: 83, matchedTags: ['Python', '보안', 'Linux', '네트워크'], deadline: '2026-03-05', dDay: 24, logoColor: 'from-green-700 to-green-900', description: '국가 사이버 침해사고 대응 및 분석', benefits: ['4대보험', '교육비', '안정적근무'], requirements: ['Python 역량', '보안 분석 경험', '네트워크 프로토콜 이해'], scrapped: false },
  { id: 68, company: 'NIA 한국지능정보사회진흥원', title: '디지털 전환 시스템 개발자', location: '대구 동구', region: '대구', salary: '회사 내규', salaryMin: 3500, companySize: '공기업', matchScore: 76, matchedTags: ['Java', 'Spring Boot', 'SQL', 'Git'], deadline: '2026-04-30', dDay: 80, logoColor: 'from-blue-500 to-indigo-600', description: '국가 디지털 전환 사업 시스템 개발', benefits: ['4대보험', '교육비', '안정적근무'], requirements: ['Java/Spring 역량', 'SQL 활용', '공공사업 경험 우대'], scrapped: false },

  // 스타트업
  { id: 69, company: '뱅크샐러드', title: '백엔드 개발자 (Kotlin)', location: '서울 강남구', region: '서울', salary: '4,000~6,000만원', salaryMin: 4000, companySize: '스타트업', matchScore: 89, matchedTags: ['Java', 'Spring Boot', 'Kafka', 'AWS'], deadline: '2026-02-15', dDay: 6, logoColor: 'from-emerald-500 to-teal-600', description: '마이데이터 기반 금융 서비스 백엔드 개발', benefits: ['스톡옵션', '자율출퇴근', '식비지원'], requirements: ['Kotlin/Java 역량', 'Kafka 이해', 'AWS 인프라 경험'], scrapped: false },
  { id: 70, company: '당근마켓', title: 'SRE 엔지니어', location: '서울 서초구', region: '서울', salary: '5,000~7,000만원', salaryMin: 5000, companySize: '스타트업', matchScore: 90, matchedTags: ['Kubernetes', 'Docker', 'AWS', 'CI/CD'], deadline: '2026-02-20', dDay: 11, logoColor: 'from-orange-400 to-orange-600', description: '대규모 트래픽 서비스 안정성 확보 및 인프라 운영', benefits: ['원격근무', '장비지원', '식비지원'], requirements: ['K8s/Docker 운영', 'AWS 인프라 숙련', '모니터링 시스템 구축'], scrapped: false },
  { id: 71, company: '야놀자', title: '검색 엔진 개발자', location: '서울 강남구', region: '서울', salary: '4,000~6,000만원', salaryMin: 4000, companySize: '스타트업', matchScore: 84, matchedTags: ['Java', 'Spring Boot', 'Redis', 'Docker'], deadline: '2026-03-01', dDay: 20, logoColor: 'from-rose-500 to-pink-600', description: '숙박/여행 플랫폼 검색 서비스 개발', benefits: ['재택근무', '호텔할인', '4대보험'], requirements: ['Java/Spring 역량', 'Elasticsearch 경험', 'Redis 활용'], scrapped: false },
  { id: 72, company: '클래스101', title: 'React 프론트엔드 개발자', location: '서울 강남구', region: '서울', salary: '3,500~5,000만원', salaryMin: 3500, companySize: '스타트업', matchScore: 86, matchedTags: ['React', 'TypeScript', 'Git', 'AWS'], deadline: '2026-02-25', dDay: 16, logoColor: 'from-red-400 to-red-600', description: '온라인 클래스 플랫폼 프론트엔드 개발', benefits: ['스톡옵션', '자율출퇴근', '클래스무료'], requirements: ['React/TypeScript 숙련', 'AWS 기초', '웹 성능 최적화'], scrapped: false },
];

const regions = ['전체', '서울', '경기', '인천', '부산', '대전', '대구', '광주', '성남', '수원'];
const salaryRanges = ['전체', '3천만원 이상', '4천만원 이상', '5천만원 이상'];
const companySizes = ['전체', '대기업', '중견기업', '중소기업', '공기업', '스타트업'];

type SortKey = 'matchScore' | 'salaryMin' | 'dDay';

function getScoreColor(score: number): string {
  if (score >= 90) return 'text-success-600 bg-success-50 dark:bg-success-900/20 border-success-200 dark:border-success-800';
  if (score >= 80) return 'text-primary-600 bg-primary-50 dark:bg-primary-900/20 border-primary-200 dark:border-primary-800';
  if (score >= 70) return 'text-warning-600 bg-warning-50 dark:bg-warning-900/20 border-warning-200 dark:border-warning-800';
  return 'text-gray-600 bg-gray-50 dark:bg-gray-900/20 border-gray-200 dark:border-gray-800';
}

function getDDayColor(dDay: number): string {
  if (dDay <= 7) return 'text-danger-600';
  if (dDay <= 14) return 'text-warning-600';
  return 'text-gray-500';
}

const ITEMS_PER_PAGE = 8;

export default function JobRecommendPage() {
  const { t } = useTranslation();
  const [regionFilter, setRegionFilter] = useState('전체');
  const [salaryFilter, setSalaryFilter] = useState('전체');
  const [sizeFilter, setSizeFilter] = useState('전체');
  const [sortKey, setSortKey] = useState<SortKey>('matchScore');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedJob, setSelectedJob] = useState<JobPosting | null>(null);
  const [toast, setToast] = useState('');
  const [scrappedJobs, setScrappedJobs] = useState<Set<number>>(
    new Set(mockJobs.filter(j => j.scrapped).map(j => j.id))
  );

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(''), 2000);
  };

  const toggleScrap = (id: number, e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    setScrappedJobs(prev => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
        showToast('스크랩이 해제되었습니다.');
      } else {
        next.add(id);
        showToast('스크랩에 저장되었습니다.');
      }
      return next;
    });
  };

  // 필터링 + 정렬
  const filtered = useMemo(() => {
    let result = mockJobs.filter(job => {
      const matchRegion = regionFilter === '전체' || job.region === regionFilter;
      const matchSize = sizeFilter === '전체' || job.companySize === sizeFilter;
      let matchSalary = true;
      if (salaryFilter === '3천만원 이상') matchSalary = job.salaryMin >= 3000;
      else if (salaryFilter === '4천만원 이상') matchSalary = job.salaryMin >= 4000;
      else if (salaryFilter === '5천만원 이상') matchSalary = job.salaryMin >= 5000;
      return matchRegion && matchSize && matchSalary;
    });

    // 정렬
    result.sort((a, b) => {
      if (sortKey === 'matchScore') return b.matchScore - a.matchScore;
      if (sortKey === 'salaryMin') return b.salaryMin - a.salaryMin;
      if (sortKey === 'dDay') return a.dDay - b.dDay;
      return 0;
    });

    return result;
  }, [regionFilter, salaryFilter, sizeFilter, sortKey]);

  // 페이지네이션
  const totalPages = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const paginatedJobs = useMemo(() => {
    const start = (currentPage - 1) * ITEMS_PER_PAGE;
    return filtered.slice(start, start + ITEMS_PER_PAGE);
  }, [filtered, currentPage]);

  // 필터 변경 시 페이지 리셋
  const handleFilterChange = (setter: (v: string) => void, value: string) => {
    setter(value);
    setCurrentPage(1);
  };

  const handlePageChange = (page: number) => {
    if (page >= 1 && page <= totalPages) setCurrentPage(page);
  };

  const getPageNumbers = (): (number | string)[] => {
    const pages: (number | string)[] = [];
    if (totalPages <= 5) {
      for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else {
      pages.push(1);
      if (currentPage > 3) pages.push('...');
      const start = Math.max(2, currentPage - 1);
      const end = Math.min(totalPages - 1, currentPage + 1);
      for (let i = start; i <= end; i++) pages.push(i);
      if (currentPage < totalPages - 2) pages.push('...');
      pages.push(totalPages);
    }
    return pages;
  };

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.jobsTitle')}</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">
            {t('student.jobsDesc')}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="badge-sm badge-info flex items-center gap-1">
            <Briefcase className="w-3 h-3" />
            {filtered.length}개 공고
          </span>
        </div>
      </div>

      {/* 필터 */}
      <div className="card p-4 space-y-3">
        <div className="flex items-center gap-1.5 text-xs text-gray-500">
          <Filter className="w-3.5 h-3.5" />
          <span className="font-medium">필터</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div>
            <label className="text-[10px] text-gray-400 mb-1 block">지역</label>
            <div className="filter-bar">
              {regions.map(r => (
                <button
                  key={r}
                  onClick={() => handleFilterChange(setRegionFilter, r)}
                  className={`filter-chip text-[10px] ${regionFilter === r ? 'filter-chip-active' : 'filter-chip-inactive'}`}
                >
                  {r}
                </button>
              ))}
            </div>
          </div>
          <div>
            <label className="text-[10px] text-gray-400 mb-1 block">연봉</label>
            <div className="filter-bar">
              {salaryRanges.map(s => (
                <button
                  key={s}
                  onClick={() => handleFilterChange(setSalaryFilter, s)}
                  className={`filter-chip text-[10px] ${salaryFilter === s ? 'filter-chip-active' : 'filter-chip-inactive'}`}
                >
                  {s}
                </button>
              ))}
            </div>
          </div>
          <div>
            <label className="text-[10px] text-gray-400 mb-1 block">기업규모</label>
            <div className="filter-bar">
              {companySizes.map(c => (
                <button
                  key={c}
                  onClick={() => handleFilterChange(setSizeFilter, c)}
                  className={`filter-chip text-[10px] ${sizeFilter === c ? 'filter-chip-active' : 'filter-chip-inactive'}`}
                >
                  {c}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* 정렬 */}
      <div className="flex items-center justify-between">
        <span className="text-xs text-gray-500 dark:text-gray-400">
          총 {filtered.length}건 중 {Math.min((currentPage - 1) * ITEMS_PER_PAGE + 1, filtered.length)}-{Math.min(currentPage * ITEMS_PER_PAGE, filtered.length)} 표시
        </span>
        <div className="flex items-center gap-1">
          <ArrowUpDown className="w-3 h-3 text-gray-400" />
          {(['matchScore', 'salaryMin', 'dDay'] as SortKey[]).map(key => (
            <button
              key={key}
              onClick={() => { setSortKey(key); setCurrentPage(1); }}
              className={`px-2.5 py-1 text-[10px] rounded-md transition-colors ${
                sortKey === key
                  ? 'bg-primary-600 text-white'
                  : 'text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700'
              }`}
            >
              {key === 'matchScore' ? '매칭률순' : key === 'salaryMin' ? '연봉순' : '마감임박순'}
            </button>
          ))}
        </div>
      </div>

      {/* 공고 카드 리스트 */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {paginatedJobs.map(job => (
          <div
            key={job.id}
            onClick={() => setSelectedJob(job)}
            className="card p-4 hover:shadow-card-hover transition-all cursor-pointer hover:border-primary-200 dark:hover:border-primary-800 relative"
          >
            {/* 매칭 스코어 뱃지 */}
            <div className={`absolute top-3 right-3 px-2 py-1 rounded-lg border text-xs font-bold ${getScoreColor(job.matchScore)}`}>
              {job.matchScore}%
            </div>

            {/* 기업 정보 */}
            <div className="flex items-start gap-3 mb-3">
              <div className={`w-10 h-10 rounded-lg bg-gradient-to-br ${job.logoColor} flex items-center justify-center shrink-0`}>
                <span className="text-white text-sm font-bold">{job.company[0]}</span>
              </div>
              <div className="flex-1 min-w-0 pr-12">
                <div className="text-xs text-gray-500 dark:text-slate-400">{job.company}</div>
                <div className="text-sm font-semibold text-gray-900 dark:text-white mt-0.5 text-truncate">
                  {job.title}
                </div>
              </div>
            </div>

            {/* 상세 정보 */}
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[10px] text-gray-500 dark:text-slate-400 mb-3">
              <span className="flex items-center gap-1"><MapPin className="w-3 h-3" />{job.location}</span>
              <span className="flex items-center gap-1"><DollarSign className="w-3 h-3" />{job.salary}</span>
              <span className="flex items-center gap-1"><Building2 className="w-3 h-3" />{job.companySize}</span>
              <span className={`flex items-center gap-1 font-medium ${getDDayColor(job.dDay)}`}>
                <Clock className="w-3 h-3" />D-{job.dDay}
              </span>
            </div>

            <p className="text-xs text-gray-600 dark:text-slate-400 mb-3">{job.description}</p>

            {/* 매칭된 태그 */}
            <div className="flex flex-wrap gap-1 mb-3">
              {job.matchedTags.map(tag => (
                <span
                  key={tag}
                  className="text-[10px] px-2 py-0.5 rounded-full bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400 border border-primary-100 dark:border-primary-800 font-medium"
                >
                  #{tag}
                </span>
              ))}
            </div>

            {/* 액션 */}
            <div className="flex items-center justify-between pt-2 border-t border-gray-50 dark:border-slate-800">
              <div className="flex gap-1">
                {job.benefits.map(b => (
                  <span key={b} className="text-[9px] px-1.5 py-0.5 bg-gray-50 dark:bg-slate-800 text-gray-400 rounded">
                    {b}
                  </span>
                ))}
              </div>
              <div className="flex items-center gap-1.5">
                <button
                  onClick={(e) => toggleScrap(job.id, e)}
                  className="p-1.5 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors"
                >
                  <Heart
                    className={`w-4 h-4 ${scrappedJobs.has(job.id) ? 'fill-danger-500 text-danger-500' : 'text-gray-300'}`}
                  />
                </button>
                <button
                  onClick={(e) => { e.stopPropagation(); setSelectedJob(job); }}
                  className="btn-sm btn-primary text-[10px] flex items-center gap-1"
                >
                  상세보기
                  <ChevronRight className="w-3 h-3" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="card p-8 text-center">
          <Briefcase className="w-8 h-8 text-gray-300 mx-auto mb-2" />
          <p className="text-sm text-gray-500">필터 조건에 맞는 공고가 없습니다.</p>
        </div>
      )}

      {/* 페이지네이션 */}
      {filtered.length > ITEMS_PER_PAGE && (
        <div className="flex items-center justify-center gap-1 pt-2">
          <button
            onClick={() => handlePageChange(currentPage - 1)}
            disabled={currentPage === 1}
            className="flex items-center gap-1 rounded-md px-3 py-2 text-xs text-gray-600 hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed dark:text-gray-400 dark:hover:bg-gray-700"
          >
            <ChevronLeft className="w-3.5 h-3.5" />
          </button>
          {getPageNumbers().map((page, idx) =>
            typeof page === 'string' ? (
              <span key={`e-${idx}`} className="px-2 text-xs text-gray-400">...</span>
            ) : (
              <button
                key={page}
                onClick={() => handlePageChange(page)}
                className={`min-w-[32px] rounded-md px-3 py-2 text-xs font-medium transition-colors ${
                  currentPage === page
                    ? 'bg-primary-600 text-white'
                    : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
                }`}
              >
                {page}
              </button>
            )
          )}
          <button
            onClick={() => handlePageChange(currentPage + 1)}
            disabled={currentPage === totalPages}
            className="flex items-center gap-1 rounded-md px-3 py-2 text-xs text-gray-600 hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed dark:text-gray-400 dark:hover:bg-gray-700"
          >
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* 공고 상세 모달 */}
      {selectedJob && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm"
          onClick={() => setSelectedJob(null)}
        >
          <div
            className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-lg mx-4 overflow-hidden max-h-[90vh] flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            {/* 모달 헤더 */}
            <div className={`relative bg-gradient-to-br ${selectedJob.logoColor} px-6 py-5 text-white`}>
              <button
                onClick={() => setSelectedJob(null)}
                className="absolute top-3 right-3 p-1.5 rounded-lg bg-white/20 hover:bg-white/30 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
              <div className="flex items-center gap-3 mb-3">
                <div className="w-12 h-12 rounded-xl bg-white/20 flex items-center justify-center">
                  <span className="text-lg font-bold">{selectedJob.company[0]}</span>
                </div>
                <div>
                  <div className="text-sm text-white/80">{selectedJob.company}</div>
                  <div className="text-lg font-bold">{selectedJob.title}</div>
                </div>
              </div>
              <div className={`inline-flex px-3 py-1 rounded-lg text-sm font-bold bg-white/20`}>
                매칭률 {selectedJob.matchScore}%
              </div>
            </div>

            {/* 모달 본문 */}
            <div className="overflow-y-auto flex-1 px-6 py-5 space-y-5">
              {/* 기본 정보 */}
              <div className="grid grid-cols-2 gap-3">
                <div className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
                  <MapPin className="w-4 h-4 text-gray-400" />
                  {selectedJob.location}
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
                  <DollarSign className="w-4 h-4 text-gray-400" />
                  {selectedJob.salary}
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
                  <Building2 className="w-4 h-4 text-gray-400" />
                  {selectedJob.companySize}
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
                  <Calendar className="w-4 h-4 text-gray-400" />
                  {selectedJob.deadline}
                  <span className={`text-xs font-medium ${getDDayColor(selectedJob.dDay)}`}>
                    (D-{selectedJob.dDay})
                  </span>
                </div>
              </div>

              {/* 직무 설명 */}
              <div>
                <div className="text-xs font-semibold text-gray-500 mb-2">직무 설명</div>
                <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
                  {selectedJob.description}
                </p>
              </div>

              {/* 자격 요건 */}
              <div>
                <div className="text-xs font-semibold text-gray-500 mb-2">자격 요건</div>
                <ul className="space-y-1.5">
                  {selectedJob.requirements.map((req, idx) => (
                    <li key={idx} className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
                      <CheckCircle className="w-3.5 h-3.5 text-green-500 flex-shrink-0" />
                      {req}
                    </li>
                  ))}
                </ul>
              </div>

              {/* 매칭 태그 */}
              <div>
                <div className="text-xs font-semibold text-gray-500 mb-2">매칭된 역량</div>
                <div className="flex flex-wrap gap-1.5">
                  {selectedJob.matchedTags.map(tag => (
                    <span
                      key={tag}
                      className="flex items-center gap-1 text-xs px-2.5 py-1 rounded-full bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400 border border-primary-100 dark:border-primary-800 font-medium"
                    >
                      <Tag className="w-3 h-3" />
                      {tag}
                    </span>
                  ))}
                </div>
              </div>

              {/* 복리후생 */}
              <div>
                <div className="text-xs font-semibold text-gray-500 mb-2">복리후생</div>
                <div className="flex flex-wrap gap-1.5">
                  {selectedJob.benefits.map(b => (
                    <span key={b} className="text-xs px-2.5 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 rounded-lg">
                      {b}
                    </span>
                  ))}
                </div>
              </div>
            </div>

            {/* 모달 하단 */}
            <div className="px-6 py-4 border-t border-gray-100 dark:border-gray-700 flex items-center gap-3">
              <button
                onClick={() => toggleScrap(selectedJob.id)}
                className={`flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg border transition-colors ${
                  scrappedJobs.has(selectedJob.id)
                    ? 'border-danger-300 text-danger-600 bg-danger-50 hover:bg-danger-100 dark:border-danger-700 dark:bg-danger-900/20'
                    : 'border-gray-300 text-gray-600 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700'
                }`}
              >
                <Heart className={`w-4 h-4 ${scrappedJobs.has(selectedJob.id) ? 'fill-danger-500' : ''}`} />
                {scrappedJobs.has(selectedJob.id) ? '스크랩 해제' : '스크랩'}
              </button>
              <button
                onClick={() => {
                  showToast('지원 페이지로 이동합니다.');
                  setSelectedJob(null);
                }}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-lg hover:bg-primary-700 transition-colors"
              >
                <ExternalLink className="w-4 h-4" />
                지원하기
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 토스트 */}
      {toast && (
        <div className="fixed bottom-6 right-6 z-[60] flex items-center gap-3 bg-green-600 text-white px-5 py-3 rounded-xl shadow-lg">
          <CheckCircle className="w-5 h-5" />
          <span className="text-sm font-medium">{toast}</span>
        </div>
      )}
    </div>
  );
}
