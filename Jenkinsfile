#!groovy
milestone 0
def repo = "cas"
def dockerUser = "discoenv"

def JENKINS_CREDS = [[$class: 'UsernamePasswordMultiBinding',
                      credentialsId: 'jenkins-docker-credentials',
                      passwordVariable: 'DOCKER_PASSWORD',
                      usernameVariable: 'DOCKER_USERNAME']]

timestamps {
    node('docker') {
        slackJobDescription = "job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
        try {
            stage "Prepare"
            checkout scm
            git_commit = sh(returnStdout: true, script: "git rev-parse HEAD").trim()
            echo git_commit

            descriptive_version = sh(returnStdout: true, script: 'git describe --long --tags --dirty --always').trim()
            echo descriptive_version

            dockerWarBuilder = "war-${repo}"
            dockerPusher = "push-${repo}"

            try {
                stage "Build WAR"
                sh "mkdir -p target/"
                sh """docker run --rm -v "\$(pwd):/build" -w /build --name ${dockerWarBuilder} maven:slim mvn package"""

                fingerprint 'target/cas.war'

                stage "Package Public Image and Push"

                milestone 100
                dockerRepo = "${dockerUser}/${repo}:${env.BRANCH_NAME}"
                lock("docker-push-${dockerRepo}") {
                    milestone 101
                    sh """docker build --rm \\
                          --build-arg git_commit=${git_commit} \\
                          --build-arg descriptive_version=${descriptive_version} \\
                          -t ${dockerRepo} ."""

                    image_sha = sh(
                        returnStdout: true,
                        script: "docker inspect -f '{{ .Config.Image }}' ${dockerRepo}"
                    ).trim()
                    echo image_sha

                    writeFile(file: "${dockerRepo}.docker-image-sha", text: "${image_sha}")
                    fingerprint "${dockerRepo}.docker-image-sha"

                    withCredentials(JENKINS_CREDS) {
                        sh """docker run -e DOCKER_USERNAME -e DOCKER_PASSWORD \\
                                     -v /var/run/docker.sock:/var/run/docker.sock \\
                                     --rm --name ${dockerPusher} \\
                                     docker:\$(docker version --format '{{ .Server.Version }}') \\
                                     sh -e -c \\
                          'docker login -u \"\$DOCKER_USERNAME\" -p \"\$DOCKER_PASSWORD\" && \\
                           docker push ${dockerRepo} && \\
                           docker logout'"""
                    }
                }
            } finally {
                // using returnStatus so if these are gone it doesn't error
                sh returnStatus: true, script: "docker kill ${dockerWarBuilder}"
                sh returnStatus: true, script: "docker rm ${dockerWarBuilder}"

                sh returnStatus: true, script: "docker kill ${dockerPusher}"
                sh returnStatus: true, script: "docker rm ${dockerPusher}"

                step([$class: 'hudson.plugins.jira.JiraIssueUpdater',
                      issueSelector: [$class: 'hudson.plugins.jira.selector.DefaultIssueSelector'],
                      scm: scm,
                      labels: [ "ui-${descriptive_version}" ]])
            }

        } catch (InterruptedException e) {
            currentBuild.result = "ABORTED"
            slackSend color: 'warning', message: "ABORTED: ${slackJobDescription}"
            throw e
        } catch (e) {
            currentBuild.result = "FAILED"
            sh "echo ${e}"
            slackSend color: 'danger', message: "FAILED: ${slackJobDescription}"
            throw e
        }
    }
}
