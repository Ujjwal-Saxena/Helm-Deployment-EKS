def envVars = env.getEnvironment()

def err = null

properties([
  parameters([
    string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'Branch to build/deploy'),
    string(name: 'REPO_URL',   defaultValue: 'https://github.com/Monotype/EKS-Helm-deploy.git', description: 'Git repository URL'),
  ])
])

// Hard‑coded settings
def EKS_CLUSTER   = 'r360-nonprod'
def AWS_ACCOUNT   = '043309366514'
def K8S_NAMESPACE = 'jenkins-helm'
def AWS_REGION    = 'us-east-1'
def ts = new Date().format("yyyyMMddHHmmss")
def imageName = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/jenkins-helm-img:${ts}"

node('r360-build') {
  stage('Clean') { deleteDir() }

  stage('Checkout') {
    checkout([
      $class: 'GitSCM',
      branches: [[ name: "*/${params.GIT_BRANCH}" ]],
      userRemoteConfigs: [[ credentialsId: 'Jenkins-Monotype-Github', url: params.REPO_URL ]]
    ])
  }

  stage('Gather') {
    sh '''
      mkdir -p artifacts
      cp Dockerfile .env artifacts/
      cp -r helm artifacts/helm
    '''
    stash name: 'artifacts', includes: 'artifacts/**'
  }

  stage('Build & Push') {
    unstash 'artifacts'
    dir('artifacts') {
      echo "Building image ${imageName}"
      withCredentials([usernamePassword(credentialsId: 'Jenkins-Monotype-Github', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
          docker build -t ${imageName} .
          docker push ${imageName}
        """
      }
      env.IMAGE = imageName
    }
    stash name: 'deployment', includes: 'artifacts/**'
  }
}

node('R360-PP-Bastion') {
        deleteDir()
        unstash 'deployment'

  stage('Helm Deploy') {
  withEnv(["AWS_PROFILE=eksprofile"]) {
    unstash 'artifacts'

    dir('artifacts/helm') {
      sh """
        mkdir -p $HOME/bin
        export PATH=$HOME/bin:$PATH
        # Install yq if not found
        if ! command -v yq >/dev/null 2>&1; then
          echo "Installing yq..."
          wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O $HOME/bin/yq
          chmod +x $HOME/bin/yq
        fi
        
        # Extract namespace from values.yaml
        ns=\$(yq '.namespace' values.yaml)

        echo "Using namespace: \$ns"

        # Create namespace only if it doesn't exist
        if ! kubectl get ns \$ns >/dev/null 2>&1; then
          echo "Namespace '\$ns' does not exist. Creating..."
          kubectl create ns \$ns
        else
          echo "Namespace '\$ns' already exists."
        fi

        # Deploy using Helm
        helm upgrade --install jenkins-app . \\
          --namespace \$ns \\
          --set image.repository=${imageName.split(':')[0]} \\
          --set image.tag=${imageName.split(':')[1]} \\
          --wait

        # Post-deployment checks
        echo "Deployed resources in namespace \$ns:"
        kubectl get all -n \$ns
        helm list -n \$ns
      """
    }
  }
}
}
