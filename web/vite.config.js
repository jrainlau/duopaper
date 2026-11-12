import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// GitHub Pages 项目站点部署在 /duopaper/ 子路径下；本地 dev 保持根路径 /。
// 构建时 index.html 里的 %BASE_URL% 会被替换成这里的 base。
export default defineConfig(({ command }) => ({
  base: command === 'build' ? '/duopaper/' : '/',
  plugins: [react()],
  // host:true 监听 0.0.0.0，让同一局域网的真机可以访问。
  // 允许 Bonjour 名（xxx.local）访问，Vite 默认只放行 localhost 与 IP 字面量。
  server: {
    host: true,
    port: 8088,
    strictPort: true,
    allowedHosts: ['.local'],
    // 真机调试时手机只跟 Mac 通信：绕开手机直连 Unsplash 不通、以及跨域预检。
    // 仅 dev 生效；生产构建仍直连官方地址，保持 hotlinking 与 ixid 统计。
    proxy: {
      '/unsplash-api': {
        target: 'https://api.unsplash.com',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/unsplash-api/, ''),
      },
      '/unsplash-img': {
        target: 'https://images.unsplash.com',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/unsplash-img/, ''),
      },
    },
  },
  preview: { host: true, port: 4173 },
}));
