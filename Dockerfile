FROM nginx:alpine
RUN echo "<html><body><h1>Hello from EKS! 🚀</h1></body></html>" > /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
