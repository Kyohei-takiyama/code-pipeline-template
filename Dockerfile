FROM nginx:latest

FROM nginx
COPY src /usr/share/nginx/html

RUN service nginx start

EXPOSE 80