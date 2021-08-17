FROM jenkins/jenkins:2.289.2-lts-jdk11

USER root

# Install Docker installation dependencies and Vim.
RUN apt-get update && apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  software-properties-common \
  vim

# Install Docker.
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN apt-key fingerprint 0EBFCD88
RUN add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable"
RUN apt-get update && apt-get install -y docker-ce-cli

# Install Docker Compose.
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# Install Jenkins dependencies.
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean:1.24.7 docker-workflow:1.26"

# Add SSH key folder as Jenkins user to ensure correct permissions.
RUN mkdir /var/jenkins_home/.ssh

EXPOSE 8080 50000
