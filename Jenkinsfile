
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        TF_IN_AUTOMATION = 'true'
    }

    stages {

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init and Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init -input=false
                        terraform validate
                        terraform plan -input=false -out=tfplan
                    '''
                }
            }
        }

        stage('Manual Approval') {
            steps {
                input message: 'Approve PostgreSQL infrastructure deployment?',
                      ok: 'Deploy'
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -input=false -auto-approve tfplan'

                    script {
                        env.DB_HOST = sh(
                            script: 'terraform output -raw postgres_private_ip',
                            returnStdout: true
                        ).trim()
                    }
                }

                echo "PostgreSQL Server IP: ${env.DB_HOST}"
            }
        }

        stage('Ansible PostgreSQL Configuration') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'postgres-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    )
                ]) {
                    sh '''
                        export ANSIBLE_HOST_KEY_CHECKING=False

                        ansible-playbook \
                          -i "${DB_HOST}," \
                          ansible/install-postgresql.yml \
                          -u ubuntu \
                          --private-key "$SSH_KEY"
                    '''
                }
            }
        }

        stage('Database Connection Test') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'postgres-db-password',
                        variable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        PGPASSWORD="$DB_PASSWORD" psql \
                          -h "$DB_HOST" \
                          -p 5432 \
                          -U appuser \
                          -d appdb \
                          -c "SELECT current_database(), current_user, version();"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: PostgreSQL One-Click Deployment Completed!'
        }

        failure {
            echo 'FAILED: Please check Jenkins Console Output.'
        }
    }
}

