def call() {

    stage('Clone') {
        echo 'Clone PostgreSQL code'
    }

    stage('User Approval') {
        input message: 'Approve PostgreSQL deployment?'
    }

    stage('Playbook Execution') {
        echo 'Execute PostgreSQL Ansible playbook'
    }

    stage('Notification') {
        echo 'Send notification'
    }
}
