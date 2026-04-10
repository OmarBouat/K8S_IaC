pipeline {
  agent any

  options {
    disableConcurrentBuilds()
  }

  triggers {
    githubPush()
    pollSCM('H/2 * * * *')
  }

  environment {
    APP_IMAGE = 'k8s-lab/frontend'
    APP_CONTAINER = 'frontend-web'
    APP_PORT = '8090'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        script {
          def shortCommit = sh(script: 'git rev-parse --short=12 HEAD', returnStdout: true).trim()
          def buildTime = sh(script: 'date -u +%Y-%m-%dT%H:%M:%SZ', returnStdout: true).trim()
          def buildContext = sh(
            script: '''
              if [ -f Dockerfile ]; then
                echo .
              elif [ -f frontend/Dockerfile ]; then
                echo frontend
              else
                echo "No Dockerfile found at repository root or frontend/" >&2
                exit 1
              fi
            ''',
            returnStdout: true
          ).trim()

          env.APP_TAG = shortCommit
          env.APP_LATEST = "${APP_IMAGE}:latest"
          env.APP_VERSIONED = "${APP_IMAGE}:${shortCommit}"

          sh """
            set -e
            docker build \\
              --build-arg APP_COMMIT=${shortCommit} \\
              --build-arg APP_BUILD_TIME=${buildTime} \\
              -t ${APP_LATEST} \\
              -t ${APP_VERSIONED} \\
              ${buildContext}
          """
        }
      }
    }

    stage('Deploy Container') {
      steps {
        sh """
          set -e
          docker rm -f ${APP_CONTAINER} 2>/dev/null || true
          docker run -d \\
            --name ${APP_CONTAINER} \\
            --restart unless-stopped \\
            -p ${APP_PORT}:80 \\
            ${APP_LATEST}
        """
      }
    }

    stage('Smoke Test') {
      steps {
        sh """
          set -e
          for i in \$(seq 1 30); do
            if curl -fsS http://host.docker.internal:${APP_PORT}/health >/dev/null; then
              exit 0
            fi
            sleep 2
          done
          echo 'Frontend health endpoint did not become ready in time.'
          exit 1
        """
      }
    }
  }

  post {
    success {
      echo "Deployment successful: http://192.168.56.20:${APP_PORT}"
      echo "Image tags: ${APP_LATEST}, ${APP_VERSIONED}"
    }
    failure {
      echo 'Deployment failed. Check Docker daemon and container logs.'
    }
  }
}
