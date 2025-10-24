# 1) 경량 Nginx
FROM nginx:alpine

# 2) SPA 라우팅 & 캐시 정책 설정
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 3) Flutter 빌드 결과 복사
COPY build/web/ /usr/share/nginx/html/

# 4) 건강상태 체크를 위한 기본 설정(옵션)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -qO- http://localhost/ || exit 1
