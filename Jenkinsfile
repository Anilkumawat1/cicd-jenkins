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

            when {
                buildingTag()
            }

            steps {
                echo "🏷️ Release tag detected: ${TAG_NAME}"
                echo "🐳 Building Docker image: ${IMAGE_NAME}:${TAG_NAME}"

                sh '''
                    docker build \
                        -t ${IMAGE_NAME}:${TAG_NAME} \
                        -t ${IMAGE_NAME}:latest .
                '''

                echo '✅ Docker image built successfully.'
            }
        }

        stage('Docker Push') {

            when {
                buildingTag()
            }

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

                            echo "📤 Pushing ${IMAGE_NAME}:${TAG_NAME}..."

                            sh '''
                                docker push ${IMAGE_NAME}:${TAG_NAME}
                            '''

                            echo "📤 Pushing ${IMAGE_NAME}:latest..."

                            sh '''
                                docker push ${IMAGE_NAME}:latest
                            '''

                            echo '✅ Docker images pushed to GHCR successfully.'

                        } catch (Exception e) {

                            echo '''
❌ Docker push failed!

Possible causes:
- GHCR credentials are incorrect
- GitHub token does not have package write permission
- Network connectivity problem
- Docker image/tag problem
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
            script {

                if (env.TAG_NAME) {

                    echo """
========================================
🎉 RELEASE SUCCESS
========================================

Release tag:
${TAG_NAME}

Docker images:
${IMAGE_NAME}:${TAG_NAME}
${IMAGE_NAME}:latest

Images pushed to GHCR successfully.
========================================
"""

                } else {

                    echo """
========================================
🎉 CI SUCCESS
========================================

Branch:
${BRANCH_NAME}

Application built and tested successfully.

No Docker image was created because
this is not a release tag.
========================================
"""
                }
            }
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
            script {

                if (env.TAG_NAME) {

                    echo '🧹 Cleaning up release Docker images...'

                    sh '''
                        docker rmi ${IMAGE_NAME}:${TAG_NAME} || true
                        docker rmi ${IMAGE_NAME}:latest || true
                    '''

                    echo '✅ Docker cleanup completed.'

                } else {

                    echo '🧹 No Docker images were created. Cleanup not required.'
                }
            }
        }
    }
}