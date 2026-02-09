import { useState, useRef, useEffect } from 'react';
import { Bot, Send, Sparkles, User } from 'lucide-react';
import { aiApi } from '../../../services/api';
import { extractErrorMessage } from '@/utils/errorHandler';
import { useTranslation } from '@/i18n';

interface Message { role: 'user' | 'assistant'; content: string; }

export default function AiChatPage() {
  const { t } = useTranslation();
  const [messages, setMessages] = useState<Message[]>([
    { role: 'assistant', content: '안녕하세요! 저는 GrowAI 학습 도우미입니다. 강좌 내용이나 학습에 대해 무엇이든 물어보세요. 🎓' }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [sessionId, setSessionId] = useState<string | undefined>();
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  const handleSend = async () => {
    if (!input.trim() || loading) return;
    const userMsg = input.trim();
    setInput('');
    setMessages(prev => [...prev, { role: 'user', content: userMsg }]);
    setLoading(true);
    try {
      const res = await aiApi.chat(userMsg, sessionId);
      const body = res.data;
      if (body?.success && body.data?.response) {
        setMessages(prev => [...prev, { role: 'assistant', content: body.data.response }]);
        if (body.data.sessionId) setSessionId(body.data.sessionId);
      } else {
        const msg = body?.message || '응답을 받지 못했습니다. 다시 시도해주세요.';
        setMessages(prev => [...prev, { role: 'assistant', content: msg }]);
      }
    } catch (err: any) {
      const errMsg = extractErrorMessage(err);
      setMessages(prev => [...prev, { role: 'assistant', content: errMsg }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)]">
      <div className="flex items-center gap-2 mb-4">
        <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center">
          <Sparkles className="w-5 h-5 text-white" />
        </div>
        <div>
          <h1 className="text-base font-bold">{t('student.aiChatTitle')}</h1>
          <p className="text-[10px] text-gray-400">{t('student.aiChatDesc')}</p>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto space-y-4 pb-4 scrollbar-hidden">
        {messages.map((msg, i) => (
          <div key={i} className={`flex gap-3 ${msg.role === 'user' ? 'justify-end' : ''}`}>
            {msg.role === 'assistant' && (
              <div className="w-7 h-7 rounded-full bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center shrink-0">
                <Bot className="w-4 h-4 text-white" />
              </div>
            )}
            <div className={`max-w-[70%] rounded-2xl px-4 py-3 text-sm ${msg.role === 'user' ? 'bg-primary-600 text-white' : 'bg-white dark:bg-slate-800 border border-gray-100 dark:border-slate-700 text-gray-700 dark:text-slate-300'}`}>
              <div className="whitespace-pre-wrap">{msg.content}</div>
            </div>
            {msg.role === 'user' && (
              <div className="w-7 h-7 rounded-full bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center shrink-0">
                <User className="w-4 h-4 text-primary-600" />
              </div>
            )}
          </div>
        ))}
        {loading && (
          <div className="flex gap-3">
            <div className="w-7 h-7 rounded-full bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center shrink-0">
              <Bot className="w-4 h-4 text-white" />
            </div>
            <div className="bg-white dark:bg-slate-800 border border-gray-100 dark:border-slate-700 rounded-2xl px-4 py-3">
              <div className="flex gap-1"><span className="w-2 h-2 bg-gray-300 rounded-full animate-bounce" /><span className="w-2 h-2 bg-gray-300 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }} /><span className="w-2 h-2 bg-gray-300 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} /></div>
            </div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      <div className="flex gap-2 pt-3 border-t border-gray-100 dark:border-slate-800">
        <input type="text" value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && handleSend()} placeholder="질문을 입력하세요..." className="input flex-1" />
        <button onClick={handleSend} disabled={loading || !input.trim()} className="btn-primary"><Send className="w-4 h-4" /></button>
      </div>
    </div>
  );
}
