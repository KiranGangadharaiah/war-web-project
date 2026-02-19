pipeline {
    agent any

    environment {

        /* ================= TOMCAT VM ================= */
        TOMCAT_SERVER = "35.154.122.179"
        TOMCAT_USER   = "ubuntu"

        /* ================= NEXUS ================= */
        NEXUS_URL = "35.154.0.18:8081"
        NEXUS_REPOSITORY = "maven-releases"
        NEXUS_CREDENTIAL_ID = "nexus_creds"

        /* ================= SONAR ================= */
        SONAR_HOST_URL = "http://3.6.116.90:9000"
        SONAR_CREDENTIAL_ID = "sonar_creds"

        /* ================= DOCKER ================= */
        DOCKER_HUB_USERNAME = "kirangangadhar12"
        DOCKER_IMAGE = "wwp-app"

        /* ================= K8S ================= */
        K8S_NAMESPACE = "default"
        K8S_DEPLOYMENT = "wwp-deployment"
    }

    tools {
        maven "maven"
    }

    stages {

        /* ================= BUILD ================= */

        stage('Build WAR') {
            steps {
                sh 'mvn clean package -DskipTests'
                archiveArtifacts artifacts: '**/target/*.war'
            }
        }

        /* ================= SONAR ================= */

        // stage('SonarQube Analysis') {
        //     steps {
        //         withSonarQubeEnv('SonarQube Server') {

        //             withCredentials([
        //                 string(credentialsId: 'sonar_token', variable: 'SONAR_TOKEN')
        //             ]) {

        //                 sh """
        //                 mvn sonar:sonar \
        //                 -Dsonar.projectKey=wwp \
        //                 -Dsonar.projectName=wwp \
        //                 -Dsonar.host.url=${SONAR_HOST_URL} \
        //                 -Dsonar.login=$SONAR_TOKEN
        //                 """
        //             }
        //         }
        //     }
        // }

        /* ================= VERSION ================= */

        stage('Extract Version') {
            steps {
                script {
                    env.ART_VERSION = sh(
                        script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout",
                        returnStdout: true
                    ).trim()
                }

                echo "Project Version: ${ART_VERSION}"
            }
        }

        /* ================= NEXUS ================= */

        // stage('Publish to Nexus') {
        //     steps {
        //         script {

        //             def warFile = sh(
        //                 script: 'find target -name "*.war" -print -quit',
        //                 returnStdout: true
        //             ).trim()

        //             echo "Uploading: ${warFile}"

        //             nexusArtifactUploader(
        //                 nexusVersion: 'nexus3',
        //                 protocol: 'http',
        //                 nexusUrl: "${NEXUS_URL}",
        //                 groupId: 'koddas.web.war',
        //                 version: "${ART_VERSION}",
        //                 repository: "${NEXUS_REPOSITORY}",
        //                 credentialsId: "${NEXUS_CREDENTIAL_ID}",

        //                 artifacts: [[
        //                     artifactId: 'wwp',
        //                     classifier: '',
        //                     file: warFile,
        //                     type: 'war'
        //                 ]]
        //             )
        //         }
        //     }
        // }

        /* ================= DOCKER BUILD ================= */

        stage('Build Docker Image') {
            steps {
                script {

                    sh """
                    docker build -t ${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE}:${ART_VERSION} .
                    docker tag ${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE}:${ART_VERSION} \
                               ${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        /* ================= DOCKER PUSH ================= */

        stage('Push to Docker Hub') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub_creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {

                    sh """
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                    docker push ${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE}:${ART_VERSION}
                    docker push ${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE}:latest

                    docker logout
                    """
                }
            }
        }

        /* ================= K8S DEPLOY ================= */

stage('Deploy to Minikube (K8s)') {
    steps {
        script {
            sh """
            set -e  # Exit immediately if any command fails

            # Use Ubuntu user's kubeconfig
            export KUBECONFIG=/var/lib/jenkins/.kube/config

            echo "=== Current Kubernetes Context ==="
            kubectl config current-context
            kubectl config view --minify | grep namespace:

            echo "=== Checking Cluster Nodes ==="
            kubectl get nodes

            echo "=== Applying Kubernetes Manifests ==="
            kubectl apply -f k8s/ --validate=false

            echo "=== Updating Deployment Image ==="
            kubectl set image deployment/${K8S_DEPLOYMENT} \
                wwp-container=${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE}:${ART_VERSION} \
                -n ${K8S_NAMESPACE}

            echo "=== Waiting for Deployment Rollout ==="
            kubectl rollout status deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE}

            echo "=== Deployment Completed Successfully ==="
            """
        }
    }
}


        /* ================= TOMCAT VM DEPLOY ================= */

        // stage('Deploy to Tomcat VM') {
        //     steps {

        //         sh """
        //         scp -o StrictHostKeyChecking=no target/*.war \
        //         ${TOMCAT_USER}@${TOMCAT_SERVER}:/tmp/

        //         ssh -o StrictHostKeyChecking=no ${TOMCAT_USER}@${TOMCAT_SERVER} '
        //         sudo mv /tmp/*.war /opt/tomcat/webapps/wwp.war
        //         sudo systemctl restart tomcat
        //         '
        //         """
        //     }
        // }

     }

    post {

        success {
            echo '✅ CI/CD Pipeline completed successfully!'
        }

        failure {
            echo '❌ Pipeline failed. Check Jenkins logs.'
        }

        always {
            cleanWs()
        }
    }
}
