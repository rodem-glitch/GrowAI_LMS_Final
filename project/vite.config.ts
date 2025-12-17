import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  base: './',
  plugins: [react(), tailwindcss()],
  esbuild: {
    // 왜: Resin 정적파일 응답의 charset이 환경마다 달라서 한글이 깨지는 경우가 있습니다.
    //     빌드 산출물을 ASCII escape(\\uXXXX)로 고정하면, 서버 charset과 무관하게 한글이 안전하게 표시됩니다.
    charset: 'ascii',
  },
  build: {
    outDir: '../public_html/tutor_lms/app',
    emptyOutDir: true,
  },
});
