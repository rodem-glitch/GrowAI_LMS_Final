// pages/instructor/conference/LiveLecturePage.tsx — BigBlueButton 실시간 화상강의
import { useState, useCallback, useRef, useEffect } from 'react';
import { useTranslation } from '@/i18n';
import {
  Video, VideoOff, Mic, MicOff, Monitor, MonitorOff,
  Users, MessageSquare, Hand, PhoneOff, Settings,
  Plus, Clock, CheckCircle, AlertCircle, Loader2,
  Maximize2, Minimize2, Volume2, VolumeX, Copy,
  ExternalLink, ScreenShare, Camera
} from 'lucide-react';
import { useAuthStore } from '@/stores/useAuthStore';
import { conferenceApi } from '@/services/api';

interface Room {
  id: string;
  name: string;
  courseId: number;
  courseName: string;
  status: 'active' | 'ended' | 'scheduled';
  participants: number;
  createdAt: string;
  meetingUrl: string;
}

interface Participant {
  id: string;
  name: string;
  role: 'moderator' | 'viewer';
  camera: boolean;
  mic: boolean;
  hand: boolean;
  joinedAt: string;
}

interface ChatMessage {
  id: string;
  sender: string;
  message: string;
  time: string;
  type: 'user' | 'system';
}

// 데모 참가자 데이터
const demoParticipants: Participant[] = [
  { id: '1', name: '박교수 (나)', role: 'moderator', camera: true, mic: true, hand: false, joinedAt: '09:00' },
  { id: '2', name: '김민수', role: 'viewer', camera: true, mic: false, hand: false, joinedAt: '09:01' },
  { id: '3', name: '이영희', role: 'viewer', camera: false, mic: false, hand: true, joinedAt: '09:02' },
  { id: '4', name: '박지훈', role: 'viewer', camera: true, mic: false, hand: false, joinedAt: '09:01' },
  { id: '5', name: '최수연', role: 'viewer', camera: false, mic: false, hand: false, joinedAt: '09:03' },
  { id: '6', name: '정태영', role: 'viewer', camera: true, mic: false, hand: false, joinedAt: '09:04' },
];

const demoChatMessages: ChatMessage[] = [
  { id: '1', sender: '시스템', message: '화상 강의가 시작되었습니다.', time: '09:00', type: 'system' },
  { id: '2', sender: '박교수', message: '안녕하세요, 오늘은 3주차 조건문에 대해 학습합니다.', time: '09:00', type: 'user' },
  { id: '3', sender: '김민수', message: '교수님 안녕하세요!', time: '09:01', type: 'user' },
  { id: '4', sender: '이영희', message: '네 준비 완료했습니다.', time: '09:02', type: 'user' },
];

const demoCourses = [
  { id: 1, name: '프로그래밍 기초 (CS101-A)' },
  { id: 2, name: '자료구조 (CS201-B)' },
  { id: 3, name: '알고리즘 (CS301-A)' },
];

export default function LiveLecturePage() {
  const { t } = useTranslation();
  const { user } = useAuthStore();
  const [view, setView] = useState<'lobby' | 'meeting'>('lobby');

  // 로비 상태
  const [creating, setCreating] = useState(false);
  const [selectedCourse, setSelectedCourse] = useState(demoCourses[0].id);
  const [roomTitle, setRoomTitle] = useState('');
  const [rooms, setRooms] = useState<Room[]>([
    {
      id: 'growai-lms-1-demo',
      name: '프로그래밍 기초 - 3주차 실시간 강의',
      courseId: 1,
      courseName: 'CS101-A',
      status: 'active',
      participants: 6,
      createdAt: new Date().toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' }),
      meetingUrl: '',
    },
  ]);

  // 미팅 상태
  const [activeRoom, setActiveRoom] = useState<Room | null>(null);
  const [cameraOn, setCameraOn] = useState(true);
  const [micOn, setMicOn] = useState(true);
  const [screenShare, setScreenShare] = useState(false);
  const [fullscreen, setFullscreen] = useState(false);
  const [showChat, setShowChat] = useState(true);
  const [showParticipants, setShowParticipants] = useState(false);
  const [participants, setParticipants] = useState<Participant[]>(demoParticipants);
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>(demoChatMessages);
  const [chatInput, setChatInput] = useState('');
  const [elapsed, setElapsed] = useState(0);
  const chatEndRef = useRef<HTMLDivElement>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // 경과 시간 타이머
  useEffect(() => {
    if (view === 'meeting') {
      timerRef.current = setInterval(() => setElapsed(prev => prev + 1), 1000);
    }
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [view]);

  // 채팅 자동 스크롤
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chatMessages]);

  const formatTime = (sec: number) => {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  };

  // 강의실 생성
  const createRoom = useCallback(async () => {
    setCreating(true);
    const course = demoCourses.find(c => c.id === selectedCourse)!;
    const title = roomTitle || `${course.name} 실시간 강의`;

    // API 호출 시도
    try {
      await conferenceApi.createRoom({ courseId: selectedCourse, title });
    } catch { /* fallback to local */ }

    const newRoom: Room = {
      id: `growai-lms-${selectedCourse}-${Date.now()}`,
      name: title,
      courseId: selectedCourse,
      courseName: course.name,
      status: 'active',
      participants: 1,
      createdAt: new Date().toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' }),
      meetingUrl: `https://demo.bigbluebutton.org/gl/${selectedCourse}-${Date.now()}`,
    };

    setRooms(prev => [newRoom, ...prev]);
    setRoomTitle('');
    setCreating(false);
  }, [selectedCourse, roomTitle]);

  // 강의실 입장
  const enterRoom = useCallback((room: Room) => {
    setActiveRoom(room);
    setView('meeting');
    setElapsed(0);
    setChatMessages([
      ...demoChatMessages,
      { id: String(Date.now()), sender: '시스템', message: `${user?.name || '교수자'}님이 입장했습니다.`, time: new Date().toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' }), type: 'system' },
    ]);
  }, [user]);

  // 강의 종료
  const endMeeting = useCallback(() => {
    if (activeRoom) {
      setRooms(prev => prev.map(r => r.id === activeRoom.id ? { ...r, status: 'ended' as const } : r));
    }
    setView('lobby');
    setActiveRoom(null);
    if (timerRef.current) clearInterval(timerRef.current);
  }, [activeRoom]);

  // 채팅 전송
  const sendChat = useCallback(() => {
    if (!chatInput.trim()) return;
    setChatMessages(prev => [...prev, {
      id: String(Date.now()),
      sender: user?.name || '박교수',
      message: chatInput.trim(),
      time: new Date().toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' }),
      type: 'user',
    }]);
    setChatInput('');
  }, [chatInput, user]);

  // ─── 로비 뷰 ───
  if (view === 'lobby') {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('instructor.liveLectureTitle')}</h1>
          <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">{t('instructor.liveLectureDesc')}</p>
        </div>

        {/* 강의실 생성 */}
        <div className="card p-5">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 mb-4 flex items-center gap-2">
            <Plus className="w-4 h-4 text-primary-600" /> 새 강의실 개설
          </h2>
          <div className="flex items-end gap-3">
            <div className="flex-1">
              <label className="text-xs text-gray-500 dark:text-slate-400 mb-1 block">강좌 선택</label>
              <select
                value={selectedCourse}
                onChange={e => setSelectedCourse(Number(e.target.value))}
                className="input"
              >
                {demoCourses.map(c => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
            </div>
            <div className="flex-1">
              <label className="text-xs text-gray-500 dark:text-slate-400 mb-1 block">강의 제목 (선택)</label>
              <input
                value={roomTitle}
                onChange={e => setRoomTitle(e.target.value)}
                placeholder="예: 3주차 조건문 실습"
                className="input"
              />
            </div>
            <button
              onClick={createRoom}
              disabled={creating}
              className="flex items-center gap-2 px-5 py-2.5 bg-red-600 text-white text-sm font-medium rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50"
            >
              {creating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Video className="w-4 h-4" />}
              강의실 개설
            </button>
          </div>
        </div>

        {/* 활성 강의실 목록 */}
        <div className="card p-5 space-y-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300 flex items-center gap-2">
            <Video className="w-4 h-4 text-red-500" /> 강의실 목록
          </h2>

          {rooms.length === 0 ? (
            <div className="text-center py-8 text-sm text-gray-400">개설된 강의실이 없습니다.</div>
          ) : (
            <div className="space-y-3">
              {rooms.map(room => (
                <div key={room.id} className={`flex items-center justify-between p-4 rounded-xl border transition-all ${
                  room.status === 'active' ? 'border-red-200 bg-red-50/50 dark:border-red-800 dark:bg-red-900/10' : 'border-gray-200 bg-gray-50 dark:border-slate-700 dark:bg-slate-800'
                }`}>
                  <div className="flex items-center gap-4">
                    <div className={`p-2.5 rounded-lg ${room.status === 'active' ? 'bg-red-100 dark:bg-red-900/30' : 'bg-gray-200 dark:bg-slate-700'}`}>
                      <Video className={`w-5 h-5 ${room.status === 'active' ? 'text-red-600' : 'text-gray-500'}`} />
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-semibold text-gray-900 dark:text-white">{room.name}</span>
                        {room.status === 'active' && (
                          <span className="flex items-center gap-1 px-2 py-0.5 bg-red-500 text-white text-[10px] rounded-full font-medium">
                            <span className="w-1.5 h-1.5 bg-white rounded-full animate-pulse" /> LIVE
                          </span>
                        )}
                        {room.status === 'ended' && (
                          <span className="px-2 py-0.5 bg-gray-200 text-gray-600 text-[10px] rounded-full font-medium dark:bg-slate-700 dark:text-slate-400">종료</span>
                        )}
                      </div>
                      <div className="flex items-center gap-3 mt-0.5 text-xs text-gray-500 dark:text-slate-400">
                        <span>{room.courseName}</span>
                        <span className="flex items-center gap-1"><Users className="w-3 h-3" /> {room.participants}명</span>
                        <span className="flex items-center gap-1"><Clock className="w-3 h-3" /> {room.createdAt}</span>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {room.status === 'active' && (
                      <>
                        <button
                          onClick={() => enterRoom(room)}
                          className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white text-xs font-medium rounded-lg hover:bg-red-700 transition-colors"
                        >
                          <Camera className="w-3.5 h-3.5" /> 입장
                        </button>
                      </>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* BBB 안내 */}
        <div className="card p-5">
          <div className="flex items-start gap-4">
            <div className="p-3 rounded-xl bg-gradient-to-br from-red-500 to-orange-500 text-white">
              <Video className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-1">BigBlueButton 화상강의 시스템</h3>
              <p className="text-xs text-gray-500 dark:text-slate-400 leading-relaxed">
                오픈소스 웹 화상회의 플랫폼으로 화면공유, 화이트보드, 실시간 채팅, 소그룹 토의, 투표, 녹화 기능을 제공합니다.
                LMS와 완전 통합되어 출결 자동 기록, 강의 녹화 아카이브, 학습 분석이 가능합니다.
              </p>
              <div className="flex flex-wrap gap-2 mt-3">
                {['화면공유', '화이트보드', '소그룹 토의', '투표/퀴즈', '녹화', '출결 자동기록', '채팅'].map(f => (
                  <span key={f} className="px-2 py-1 bg-red-50 text-red-700 text-[10px] rounded-full font-medium dark:bg-red-900/20 dark:text-red-400">{f}</span>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // ─── 미팅 뷰 ───
  const handRaisedCount = participants.filter(p => p.hand).length;

  return (
    <div className={`flex flex-col ${fullscreen ? 'fixed inset-0 z-50 bg-slate-900' : 'h-[calc(100vh-64px)]'}`}>
      {/* 상단 바 */}
      <div className="flex items-center justify-between px-4 py-2 bg-slate-800 text-white border-b border-slate-700">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2">
            <span className="flex items-center gap-1 px-2 py-0.5 bg-red-500 text-[10px] rounded-full font-medium">
              <span className="w-1.5 h-1.5 bg-white rounded-full animate-pulse" /> REC
            </span>
            <span className="text-sm font-medium">{activeRoom?.name}</span>
          </div>
          <span className="text-xs text-slate-400 font-mono">{formatTime(elapsed)}</span>
        </div>
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-1 text-xs text-slate-300">
            <Users className="w-3.5 h-3.5" /> {participants.length}명
          </span>
          {handRaisedCount > 0 && (
            <span className="flex items-center gap-1 text-xs text-amber-400">
              <Hand className="w-3.5 h-3.5" /> {handRaisedCount}
            </span>
          )}
          <button onClick={() => setFullscreen(!fullscreen)} className="p-1.5 rounded hover:bg-slate-700 transition">
            {fullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* 메인 영역 */}
      <div className="flex-1 flex overflow-hidden">
        {/* 비디오 그리드 */}
        <div className="flex-1 bg-slate-900 p-3">
          <div className="grid grid-cols-3 gap-2 h-full">
            {/* 메인 비디오 (교수자) */}
            <div className="col-span-2 row-span-2 relative rounded-xl overflow-hidden bg-gradient-to-br from-slate-800 to-slate-700 border border-slate-600">
              {cameraOn ? (
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="text-center">
                    <div className="w-24 h-24 rounded-full bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center mx-auto mb-3">
                      <span className="text-3xl font-bold text-white">{(user?.name || '박')[0]}</span>
                    </div>
                    <div className="text-white text-sm font-medium">{user?.name || '박교수'} (나)</div>
                    <div className="text-slate-400 text-xs mt-1">발표 중</div>
                  </div>
                  {/* 시뮬레이션용 웨이브 애니메이션 */}
                  {micOn && (
                    <div className="absolute bottom-4 left-4 flex items-center gap-1">
                      {[1, 2, 3, 4].map(i => (
                        <div key={i} className="w-1 bg-green-400 rounded-full animate-pulse" style={{ height: `${8 + Math.random() * 16}px`, animationDelay: `${i * 0.1}s` }} />
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <div className="absolute inset-0 flex items-center justify-center bg-slate-800">
                  <VideoOff className="w-12 h-12 text-slate-500" />
                </div>
              )}
              <div className="absolute top-3 left-3 flex items-center gap-2">
                <span className="px-2 py-1 bg-black/50 text-white text-xs rounded-lg backdrop-blur-sm">{user?.name || '박교수'}</span>
                {screenShare && <span className="px-2 py-1 bg-blue-500/80 text-white text-[10px] rounded-lg">화면공유</span>}
              </div>
            </div>

            {/* 학생 비디오 그리드 */}
            {participants.filter(p => p.role === 'viewer').slice(0, 4).map(p => (
              <div key={p.id} className="relative rounded-xl overflow-hidden bg-slate-800 border border-slate-700">
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="text-center">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center mx-auto ${p.camera ? 'bg-gradient-to-br from-blue-500 to-cyan-500' : 'bg-slate-600'}`}>
                      <span className="text-sm font-bold text-white">{p.name[0]}</span>
                    </div>
                    <div className="text-white text-[11px] mt-1.5">{p.name}</div>
                  </div>
                </div>
                <div className="absolute top-2 right-2 flex items-center gap-1">
                  {p.hand && <Hand className="w-3.5 h-3.5 text-amber-400" />}
                  {!p.mic && <MicOff className="w-3 h-3 text-red-400" />}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* 사이드 패널 (채팅/참가자) */}
        {(showChat || showParticipants) && (
          <div className="w-80 bg-white dark:bg-slate-800 border-l border-gray-200 dark:border-slate-700 flex flex-col">
            {/* 탭 */}
            <div className="flex border-b border-gray-200 dark:border-slate-700">
              <button
                onClick={() => { setShowChat(true); setShowParticipants(false); }}
                className={`flex-1 px-4 py-2.5 text-xs font-medium transition ${showChat ? 'text-primary-600 border-b-2 border-primary-600' : 'text-gray-500'}`}
              >
                <MessageSquare className="w-3.5 h-3.5 inline mr-1" /> 채팅
              </button>
              <button
                onClick={() => { setShowParticipants(true); setShowChat(false); }}
                className={`flex-1 px-4 py-2.5 text-xs font-medium transition ${showParticipants ? 'text-primary-600 border-b-2 border-primary-600' : 'text-gray-500'}`}
              >
                <Users className="w-3.5 h-3.5 inline mr-1" /> 참가자 ({participants.length})
              </button>
            </div>

            {/* 채팅 */}
            {showChat && (
              <>
                <div className="flex-1 overflow-y-auto p-3 space-y-2">
                  {chatMessages.map(msg => (
                    <div key={msg.id} className={msg.type === 'system' ? 'text-center' : ''}>
                      {msg.type === 'system' ? (
                        <span className="text-[10px] text-gray-400 dark:text-slate-500 bg-gray-100 dark:bg-slate-700 px-2 py-0.5 rounded">{msg.message}</span>
                      ) : (
                        <div>
                          <div className="flex items-center gap-1.5">
                            <span className="text-[11px] font-medium text-gray-800 dark:text-slate-200">{msg.sender}</span>
                            <span className="text-[10px] text-gray-400">{msg.time}</span>
                          </div>
                          <p className="text-xs text-gray-600 dark:text-slate-300 mt-0.5">{msg.message}</p>
                        </div>
                      )}
                    </div>
                  ))}
                  <div ref={chatEndRef} />
                </div>
                <div className="p-3 border-t border-gray-200 dark:border-slate-700">
                  <div className="flex gap-2">
                    <input
                      value={chatInput}
                      onChange={e => setChatInput(e.target.value)}
                      onKeyDown={e => e.key === 'Enter' && sendChat()}
                      placeholder="메시지 입력..."
                      className="flex-1 px-3 py-2 text-xs border border-gray-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                    />
                    <button onClick={sendChat} className="px-3 py-2 bg-primary-600 text-white text-xs rounded-lg hover:bg-primary-700 transition">전송</button>
                  </div>
                </div>
              </>
            )}

            {/* 참가자 목록 */}
            {showParticipants && (
              <div className="flex-1 overflow-y-auto p-3 space-y-1.5">
                {participants.map(p => (
                  <div key={p.id} className="flex items-center justify-between p-2.5 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-700 transition">
                    <div className="flex items-center gap-2.5">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white ${p.role === 'moderator' ? 'bg-gradient-to-br from-purple-500 to-indigo-600' : 'bg-gradient-to-br from-blue-400 to-cyan-500'}`}>
                        {p.name[0]}
                      </div>
                      <div>
                        <div className="text-xs font-medium text-gray-800 dark:text-slate-200 flex items-center gap-1">
                          {p.name}
                          {p.role === 'moderator' && <span className="text-[9px] px-1 py-0.5 bg-purple-100 text-purple-700 rounded dark:bg-purple-900/30 dark:text-purple-400">교수자</span>}
                        </div>
                        <div className="text-[10px] text-gray-400">{p.joinedAt} 입장</div>
                      </div>
                    </div>
                    <div className="flex items-center gap-1.5">
                      {p.hand && <Hand className="w-3.5 h-3.5 text-amber-500" />}
                      {p.camera ? <Video className="w-3.5 h-3.5 text-green-500" /> : <VideoOff className="w-3.5 h-3.5 text-gray-400" />}
                      {p.mic ? <Mic className="w-3.5 h-3.5 text-green-500" /> : <MicOff className="w-3.5 h-3.5 text-gray-400" />}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* 하단 컨트롤 바 */}
      <div className="flex items-center justify-between px-6 py-3 bg-slate-800 border-t border-slate-700">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setMicOn(!micOn)}
            className={`p-3 rounded-full transition-all ${micOn ? 'bg-slate-700 hover:bg-slate-600 text-white' : 'bg-red-500 hover:bg-red-600 text-white'}`}
          >
            {micOn ? <Mic className="w-5 h-5" /> : <MicOff className="w-5 h-5" />}
          </button>
          <button
            onClick={() => setCameraOn(!cameraOn)}
            className={`p-3 rounded-full transition-all ${cameraOn ? 'bg-slate-700 hover:bg-slate-600 text-white' : 'bg-red-500 hover:bg-red-600 text-white'}`}
          >
            {cameraOn ? <Video className="w-5 h-5" /> : <VideoOff className="w-5 h-5" />}
          </button>
          <button
            onClick={() => setScreenShare(!screenShare)}
            className={`p-3 rounded-full transition-all ${screenShare ? 'bg-blue-500 hover:bg-blue-600 text-white' : 'bg-slate-700 hover:bg-slate-600 text-white'}`}
          >
            {screenShare ? <MonitorOff className="w-5 h-5" /> : <Monitor className="w-5 h-5" />}
          </button>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => { setShowChat(!showChat); setShowParticipants(false); }}
            className={`p-2.5 rounded-full transition-all ${showChat ? 'bg-primary-600 text-white' : 'bg-slate-700 text-white hover:bg-slate-600'}`}
          >
            <MessageSquare className="w-4 h-4" />
          </button>
          <button
            onClick={() => { setShowParticipants(!showParticipants); setShowChat(false); }}
            className={`p-2.5 rounded-full transition-all ${showParticipants ? 'bg-primary-600 text-white' : 'bg-slate-700 text-white hover:bg-slate-600'}`}
          >
            <Users className="w-4 h-4" />
          </button>
          <div className="w-px h-8 bg-slate-600 mx-1" />
          <button
            onClick={endMeeting}
            className="flex items-center gap-2 px-5 py-2.5 bg-red-600 text-white text-sm font-medium rounded-full hover:bg-red-700 transition-colors"
          >
            <PhoneOff className="w-4 h-4" /> 강의 종료
          </button>
        </div>
      </div>
    </div>
  );
}
