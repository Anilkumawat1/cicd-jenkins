pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ghcr.io/anilkumawat1/cicd-jenkins'
    }

    stages {

        stage('Checkout') {
            steps {
                echo '📦 Checking out source code from GitHub...'

                checkout scm

                echo '✅ Source code checkout completed.'
            }
        }

        stage('Build & Test') {
            steps {
                echo '🧪 Running tests and building Spring Boot application...'

                sh './mvnw clean package'

                echo '✅ Tests passed and JAR built successfully.'
            }
        }

        stage('Docker Build') {
            steps {
                echo "🐳 Building Docker image: ${IMAGE_NAME}:${BUILD_NUMBER}"

                sh '''
                    docker build \
                        -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                        -t ${IMAGE_NAME}:latest .
                '''

                echo '✅ Docker image built successfully.'
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'ghcr-credentials',
                            usernameVariable: 'GHCR_USER',
                            passwordVariable: 'GHCR_TOKEN'
                        )
                    ]) {

                        try {

                            echo '🔐 Logging in to GHCR...'

                            sh '''
                                echo "$GHCR_TOKEN" | docker login ghcr.io \
                                    -u "$GHCR_USER" \
                                    --password-stdin
                            '''

                            echo "📤 Pushing ${IMAGE_NAME}:${BUILD_NUMBER}..."

                            sh '''
                                docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                            '''

                            echo "📤 Pushing ${IMAGE_NAME}:latest..."

                            sh '''
                                docker push ${IMAGE_NAME}:latest
                            '''

                            echo '✅ Docker images pushed to GHCR successfully.'

                        } catch (Exception e) {

                            echo '''
❌ Docker push failed!

Check:
- GHCR credentials
- GitHub token permissions
- Network connectivity
- Docker image tags
'''

                            throw e

                        } finally {

                            echo '🔓 Logging out from GHCR...'

                            sh '''
                                docker logout ghcr.io || true
                            '''

                            echo '✅ GHCR logout completed.'
                        }
                    }
                }
            }
        }
    }

    post {

        success {
            echo """
========================================
🎉 PIPELINE SUCCESS
========================================

Application built and tested successfully.

Docker images:
${IMAGE_NAME}:${BUILD_NUMBER}
${IMAGE_NAME}:latest

Images pushed to GHCR successfully.
========================================
"""
        }

        failure {
            echo """
========================================
❌ PIPELINE FAILED
========================================

One or more stages failed.

Check the stage logs above.
========================================
"""
        }

        aborted {
            echo '''
========================================
⚠️ PIPELINE ABORTED
========================================

The pipeline was manually aborted.
'''
        }

        always {
            echo '🧹 Cleaning up local Docker images...'

            sh '''
                docker rmi ${IMAGE_NAME}:${BUILD_NUMBER} || true
                docker rmi ${IMAGE_NAME}:latest || true

                echo '✅ Docker cleanup completed.'
            '''
        }
    }
}