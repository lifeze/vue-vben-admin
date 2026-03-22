# node 构建
FROM node:20-alpine as build-stage
# 署名
LABEL maintainer="lifezekun <lifezekun@163.com>"

WORKDIR /app

# 1. 先复制依赖文件（利用 Docker 缓存层）
COPY package.json pnpm-lock.yaml ./

# 设置 npm 镜像源（解决证书问题）
RUN npm config set registry https://registry.npmmirror.com && \
    npm config set strict-ssl false

# 安装 pnpm（指定版本，避免兼容性问题）
RUN npm install -g pnpm@8.15.4

# 设置 pnpm 镜像源
RUN pnpm config set registry https://registry.npmmirror.com

# 安装依赖
RUN pnpm install --frozen-lockfile

# 2. 复制源代码（依赖安装后再复制，充分利用缓存）
COPY . ./

# 设置 Node 内存限制
ENV NODE_OPTIONS=--max-old-space-size=16384

# 编译构建
RUN pnpm build:docker

# node部分结束
RUN echo "🎉 编 🎉 译 🎉 成 🎉 功 🎉"

# nginx 部署
FROM nginx:1.23.3-alpine as production-stage

# 复制构建产物
COPY --from=build-stage /app/dist /usr/share/nginx/html/dist
COPY --from=build-stage /app/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

# 启动脚本（将环境变量替换和启动合并）
CMD sed -i "s|__vg_base_url|$VG_BASE_URL|g" /usr/share/nginx/html/dist/assets/index.js && \
    sed -i "s|__vg_base_url|$VG_BASE_URL|g" /usr/share/nginx/html/dist/_app.config.js && \
    nginx -g 'daemon off;'
RUN echo "🎉 架 🎉 设 🎉 成 🎉 功 🎉"