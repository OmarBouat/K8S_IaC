FROM nginx:1.27-alpine

ARG APP_COMMIT=local
ARG APP_BUILD_TIME=unknown

RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY index.html /usr/share/nginx/html/index.html
COPY styles.css /usr/share/nginx/html/styles.css
COPY app.js /usr/share/nginx/html/app.js

RUN printf 'window.__BUILD_META__ = { commit: "%s", time: "%s" };\n' "$APP_COMMIT" "$APP_BUILD_TIME" > /usr/share/nginx/html/build-meta.js \
    && sed -i 's|<script src="app.js"></script>|<script src="build-meta.js"></script><script src="app.js"></script>|' /usr/share/nginx/html/index.html

EXPOSE 80
