# Imagen base de Jenkins con Docker y Python
FROM jenkins/jenkins:lts

# Cambiar a usuario root para instalar dependencias
USER root

# Instalar Docker CLI
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Instalar Python 3.11, Java (para ZAP) y wget
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    default-jre \
    && rm -rf /var/lib/apt/lists/*

# Instalar OWASP ZAP
RUN wget -q https://github.com/zaproxy/zaproxy/releases/download/v2.14.0/ZAP_2.14.0_Linux.tar.gz -O /tmp/zap.tar.gz \
    && tar -xzf /tmp/zap.tar.gz -C /opt \
    && rm /tmp/zap.tar.gz \
    && ln -s /opt/ZAP_2.14.0/zap.sh /usr/local/bin/zap.sh

# Crear enlaces simbólicos de Python
RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# Dar permisos al usuario jenkins para usar Docker
RUN usermod -aG docker jenkins || true

# Volver al usuario jenkins
USER jenkins

# Instalar plugins recomendados
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"
