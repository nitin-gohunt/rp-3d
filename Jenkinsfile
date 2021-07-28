def Docker_App() {
    env.DOCKER_APP = 'dops-nginx'
}

def Environment() {
    if (env.TAG_NAME) {
        if (!env.TAG_NAME.contains("-RC")) {
            env.ENVIRONMENT = 'production'
            env.STACK_NAME = 'prod-green'
        }
        else {
            env.ENVIRONMENT = 'staging'
            env.STACK_NAME = 'staging-green'
        }
    }
    else {
        if (env.GIT_BRANCH =~ 'release') {
            env.ENVIRONMENT = 'production'
            env.STACK_NAME = 'prod-green'
        }
        else {
            env.ENVIRONMENT = 'staging'
            env.STACK_NAME = 'staging-green'
        }
    }
}

def Aws_Account_Id() {
    env.AWS_ACCOUNT_ID = sh([returnStdout: true, label: 'save aws_account_id', script: "curl -s http://169.254.169.254/latest/meta-data/iam/info/ | jq -r '.InstanceProfileArn' | awk -F ':' '{print \$5 }'"]).toString().trim()
}

def Aws_Region() {
    env.REGION = 'us-west-2'
}

def Image_Tag_Append() {
    if (env.GIT_BRANCH =~ 'release') {
        env.IMAGE_TAG_APPEND = ""
    }
    else if (env.GIT_BRANCH == 'experimental') {
        env.IMAGE_TAG_APPEND = "-Snapshot"
    }
    else if (env.GIT_BRANCH == 'staging') {
        env.IMAGE_TAG_APPEND = "-RC"
    }
    else
        env.IMAGE_TAG_APPEND = "-Snapshot"
}

def Docker_App_Label() {
    env.DOCKER_APP_LABEL = sh([returnStdout: true, label: 'save docker_app_label', script: "echo \${DOCKER_APP} | tr '-' '_'"]).toString().trim()
}

def Tag() {
    if (env.TAG_NAME) {
        env.IMAGE_TAG = env.TAG_NAME
        sh "docker pull ${IMAGE_URI}:${IMAGE_TAG}"
    } else {
        env.IMAGE_TAG = sh([returnStdout: true, label: 'save image_tag', script: "echo \${BUILD_ID}\${IMAGE_TAG_APPEND}"]).toString().trim()
    }
}

def Update_Tag() {
    env.STAGING_TAG = sh([returnStdout: true, label: 'save staging_tag', script: "cat ./manifest_staging/variables.tfvars | grep \${DOCKER_APP_LABEL}_Version | awk -F '=' '{print \$2}' | tr -d '\"'"]).toString().trim()
    env.IMAGE_TAG = sh([returnStdout: true, label: 'save updated_image_tag', script: "echo \${STAGING_TAG} | awk -F '-RC' '{print \$1}'"]).toString().trim()
}

def Tf_Command_To_Run() {
    if (env.TAG_NAME != null || env.GIT_BRANCH =~ 'release' || env.GIT_BRANCH == 'experimental' || env.GIT_BRANCH == 'staging') {
        env.TF_COMMAND = "apply"
    }
    else
        env.TF_COMMAND = "plan"
}

pipeline {
    agent { label 'master' }
        stages {
            stage('SCM Checkout Primary') {
                agent { label 'master' }
                steps {
                    script {
                        Environment()
                        properties([disableConcurrentBuilds(),
                                    buildDiscarder(logRotator(daysToKeepStr: '10'))])
                    }
                    checkout([$class: 'GitSCM', branches: [[name: "refs/heads/test"]],
                    userRemoteConfigs: [[credentialsId: '8a03683d-1f49-4493-84ee-a3f6f0fd76f1', url: 'git@bitbucket.org:gohuntcom/terraform-modules.git']],
                    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'terraform-modules']]
                    ])
                    checkout([$class: 'GitSCM', branches: [[name: "refs/heads/${env.ENVIRONMENT}"]],
                    userRemoteConfigs: [[credentialsId: '8a03683d-1f49-4493-84ee-a3f6f0fd76f1', url: 'git@bitbucket.org:gohuntcom/aws-deployment-configurations.git']],
                    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'manifest']]
                    ])
                }
            }
            stage('SCM Checkout Secondary') {
                agent { label 'gohunt-manual-jenkins-slave' }
                steps {
                    checkout([$class: 'GitSCM', branches: [[name: "refs/heads/${env.ENVIRONMENT}"]],
                    userRemoteConfigs: [[credentialsId: '8a03683d-1f49-4493-84ee-a3f6f0fd76f1', url: 'git@bitbucket.org:gohuntcom/aws-deployment-configurations.git']],
                    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'manifest']]
                    ])
                    checkout([$class: 'GitSCM', branches: [[name: "refs/heads/test"]],
                    userRemoteConfigs: [[credentialsId: '8a03683d-1f49-4493-84ee-a3f6f0fd76f1', url: 'git@bitbucket.org:gohuntcom/terraform-modules.git']],
                    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'terraform-modules']]
                    ])
                }
            }
            stage('ECR Login') {
                agent { label 'master' }
                  steps {
                      script {
                          Aws_Region()
                          Docker_App()
                          Aws_Account_Id()
                          IMAGE_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${DOCKER_APP}"
                      }
                      ansiColor('xterm') {
                          sh script: './terraform-modules/scripts/ecr_login.sh'
                      }
                  }
            }
            stage('Tag') {
                agent { label 'master' }
                    steps {
                        script {
                            Image_Tag_Append()
                            Tag()
                        }
                        ansiColor('xterm') {
                            sh "echo Deploying ${IMAGE_TAG} to ${ENVIRONMENT}"
                        }
                    }
            }
            stage('Node Version') {
                when {
                    expression { GIT_BRANCH == 'experimental' || GIT_BRANCH =~ 'staging' || GIT_BRANCH =~ 'feature' && env.TAG_NAME == null }
                }
                agent { label 'master' }
                steps {
                    ansiColor('xterm') {
                        sh script: './terraform-modules/scripts/node_version.sh'
                    }
                }
            }
            stage('Update Tag') {
                when {
                    expression { GIT_BRANCH =~ 'release' && env.TAG_NAME == null }
                }
                agent { label 'master' }
                    steps {
                        checkout([$class: 'GitSCM', branches: [[name: "refs/heads/staging"]],
                        userRemoteConfigs: [[credentialsId: '8a03683d-1f49-4493-84ee-a3f6f0fd76f1', url: 'git@bitbucket.org:gohuntcom/aws-deployment-configurations.git']],
                        extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'manifest_staging']]
                        ])
                        script {
                            Docker_App_Label()
                            Update_Tag()
                        }
                        ansiColor('xterm') {
                            sh """
                              aws ecr batch-get-image --repository-name \${DOCKER_APP} --image-ids imageTag=\${STAGING_TAG} --region \${REGION} | jq -r '.images[].imageManifest' > manifest.json
                              aws ecr put-image --repository-name \${DOCKER_APP} --region \${REGION} --image-tag \${IMAGE_TAG} --image-manifest file://manifest.json
                              echo Deploying \${IMAGE_TAG} to \${ENVIRONMENT}
                              REPO=\$(echo \${GIT_URL} | awk -F '/' '{print \$5 }')
                              git remote set-url origin git@bitbucket.org:gohuntcom/\$REPO
                              git tag --force \${IMAGE_TAG}
                              git push origin \${IMAGE_TAG}
                            """
                        }
                    }
            }
            stage('Create ECR Repo') {
                when {
                    expression { GIT_BRANCH == 'experimental' || GIT_BRANCH =~ 'staging' || GIT_BRANCH =~ 'feature' && env.TAG_NAME == null }
                }
                agent { label 'master' }
                  steps {
                      ansiColor('xterm') {
                          sh script: './terraform-modules/scripts/create_ecr_repo.sh'
                      }
                  }
            }
            stage('Docker Build') {
                when {
                    expression { GIT_BRANCH == 'experimental' || GIT_BRANCH =~ 'staging' || GIT_BRANCH =~ 'feature' && env.TAG_NAME == null }
                }
                agent { label 'master' }
                  steps {
                      ansiColor('xterm') {
                          sh script: './terraform-modules/scripts/docker.sh $(pwd)'
                      }
                  }
            }
            stage('Tag Git') {
                when {
                    expression { GIT_BRANCH == 'experimental' || GIT_BRANCH =~ 'staging' && env.TAG_NAME == null }
                }
                agent { label 'master' }
                  steps {
                      ansiColor('xterm') {
                          sh script: './terraform-modules/scripts/docker.sh $(pwd)'
                          sh """
                              REPO=\$(echo \${GIT_URL} | awk -F '/' '{print \$5 }')
                              git remote set-url origin git@bitbucket.org:gohuntcom/\$REPO
                              git tag --force \${IMAGE_TAG}
                              git push origin \${IMAGE_TAG}
                          """
                      }
                  }
            }
            stage('Terraform Deploy') {
                when {
                    expression { GIT_BRANCH != 'development' }
                }
                agent { label 'gohunt-manual-jenkins-slave' }
                steps {
                    script {
                        Tf_Command_To_Run()
                    }
                    ansiColor('xterm') {
                            writeFile(file: 'infra/variables.tfvars', text: "stack_name=\"${STACK_NAME}\" \ndocker_repo=\"${IMAGE_URI}\" \nenvironment=\"${ENVIRONMENT}\" \ndocker_app=\"${DOCKER_APP}\" \nremote_state_s3_bucket=\"gohunt-production-account-tf-states\" \nregion=\"us-west-2\" \nimage_tag=\"${IMAGE_TAG}\" \n")
                        sh """
                           cd infra
                           cp ../terraform-modules/scripts/terraform/* .
                           tfenv use 1.0.1
                           ./tf.sh
                        """
                    }
                }
            }
            stage('Update Manifest') {
                when {
                    expression { env.TAG_NAME != null || GIT_BRANCH == 'experimental' || GIT_BRANCH =~ 'staging' || GIT_BRANCH =~ 'release' }
                }
                agent {
                    node { label 'master' }
                }
                steps {
                    script {
                        Docker_App_Label()
                        sh """
                        cd manifest
                        sed -i "s/\${DOCKER_APP_LABEL}_Version.*/\${DOCKER_APP_LABEL}_Version=\\\"\${IMAGE_TAG}\\\"/g" variables.tfvars
                        git add .
                        git commit -m \${DOCKER_APP_LABEL}_Version=\"\${IMAGE_TAG}\"
                        git push git@bitbucket.org:gohuntcom/aws-deployment-configurations.git HEAD:refs/heads/\${ENVIRONMENT} -f
                        """
                    }
                }
            }
    }
    post {
        always{
            cleanWs()
        }
    }
}
