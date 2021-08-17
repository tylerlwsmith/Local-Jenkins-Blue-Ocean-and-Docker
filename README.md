# Local Jenkins, Blue Ocean, and Docker

This repository contains a Docker Compose version of the Jenkins & Docker setup from the Linux/MacOS section of the Jenkins User Handbook's [installing Jenkins with Docker](https://www.jenkins.io/doc/book/installing/docker/#on-macos-and-linux) guide. The repo contains the following:

1. **A custom Jenkins image** with the Blue Ocean plugin installed out-of-the-box, allowing you to use modern CI features with Jenkins. The Jenkins container also has the ability to use an SSH key from the host machine in the Jenkins container for deploying via SSH. Keys are shared as [Docker secrets](https://docs.docker.com/engine/swarm/secrets/) and never copied into the container image, but are instead mounted as a run-time read-only resource. The container also contains VIM in case you need to edit files.
2. **A Docker-in-Docker image** that let's you run Docker and Docker Compose inside the Jenkins container.

## Setup

1. Copy the `.env.example` file into a `.env` file using the following command: `cp .env.example .env`.
2. Generate an SSH key for Jenkins on the host machine using the following command: `ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/jenkins`. This key will be used inside of the Jenkins container for authenticating via SSH for deployment. If you'd like to use your current `id_rsa` and `id_rsa.pub` keys, update the `HOST_PRIVATE_KEY` and `HOST_PUBLIC_KEY` variables in the `.env` file that you just created.
3. On your host machine, run `docker-compose up`. Watch the logs in your terminal: when Jenkins installs, it will display an initial password for logging in. If you don't see the the initial password in your terminal, you can run `docker-compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword` in a separate terminal and retrieve it there.
4. Navigate to `http://localhost:8080` in your browser. Enter the default password, click on "Install suggested plugins," create the admin user account, then set the Jenkins URL to the default value. Click "Start using Jenkins."

For future boot-ups of the services, you can run `docker-compose up -d` to allow Docker to run in the background.

## How it works

Docker runs as a background daemon, however, Docker containers can only have one root process. This makes it impractical to run Docker on the Jenkins container itself.

Fortunately, the Docker CLI does not have to be on the same machine as the Docker daemon. The CLI on the Jenkins container controls Docker on the Docker-in-Docker container via HTTP.

## Using GitHub with projects with pipelines

To build a project from GitHub, click the "Open Blue Ocean" link on the Jenkins Dashboard sidebar. In the Blue Ocean interface, click the "New Pipeline" button. When prompted about where you store your code, select "GitHub" and follow the on-screen instructions for creating an access token.

Because Jenkins is installed locally and is not Internet accessible, GitHub will not be able to notify Jenkins of changes. Because of this, you'll need to set up your Jenkinsfile so it polls your source control. Below is an example of a Jenkinsfile that polls GitHub for changes once-a-minute, and automatically starts a new build when there is a new commit:

```groovy
pipeline {
    agent any

    triggers {
      pollSCM '*/1 * * * *'
    }

    stages {
        stage('Build') {
            steps {
                echo "Hello, world!"
            }
        }
    }
}
```

## Why would you want to set up Jenkins and Docker locally?

You might want to run Jenkins and Docker locally if wanted to test them without having to go through the trouble of setting up and securing a server. If you find that Jenkins meets your needs, it's probably worth moving Jenkins to a server.

## Why not mount the host Docker Socket in the Jenkins container?

If you've read [Jérôme Petazzoni's post about using Docker-in-Docker in your CI environment](https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/), you know there are drawbacks to using Docker-in-Docker instead of mounting the host Docker socket into your container. However, on MacOS there's an impedance mismatch between the host operating system and Docker's Linux VM when it comes to file and group permissions ([here's a relevant GitHub issue](https://github.com/docker/for-mac/issues/4755)). Many of the past solutions for using the host Docker in CI have stopped working following Docker updates.

Using Docker-in-Docker with Jenkins smooths over the MacOS/Docker impedance mismatch in a dependable way that is unlikely to break with future Docker releases. While you lose out on Docker's build cache when you restart the Docker-in-Docker container, this repository is intended to be used for local testing instead of production applications.

Further, `dind` variants of the Docker-and-Docker image automatically have generated TLS certificates since version 18.09, saving you the effort of having to configure that manually if you wish to connect to remote hosts.
