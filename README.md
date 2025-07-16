# Helm-Deployment-EKS
With this you can directly verify if your dockerfile image, .env and helm chart files are configured correctly and if they will be working in EKS cluster with pods up and running.


in Jenknis UI, Select Paramterised option.
Enter 2 string parameters namely -
1. "GIT_BRANCH"
   Default Value - main
   Desc- Branch to build/deploy
2. REPO_URL
   default value - <git-url>
   desc- Git repo URL

Ensure that you further select - "Pipeline with SCM" and then correct crednetials, branch specifier to be - "*/main" and Script Path as - "Jenkinsfile".
Ensure that this Jenkinsfile shuold be in root repo in git.
