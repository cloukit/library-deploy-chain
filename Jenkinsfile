sh 'curl -sSLko pipeline-helper.groovy ${K8S_INFRASTRUCTURE_BASE_URL}pipeline-helper/pipeline-helper.groovy?v2'
def pipelineHelper = load("./pipeline-helper.groovy")
def doBuild = true
stage('branch check') {
    if (env.GWBT_BRANCH == "gh-pages") {
        doBuild = false
    }
}
pipelineHelper.nodejsTemplate {
  stage('prepare tools') {
    if(doBuild) {
      pipelineHelper.npmWriteClientConfig()
    } else {
       echo 'Skipped'
    }
  }
  stage('git clone') {
    if(doBuild) {
      sh 'git clone --single-branch --branch $GWBT_BRANCH$GWBT_TAG https://${GITHUB_AUTH_TOKEN}@github.com/${GWBT_REPO_FULL_NAME}.git source'
      dir ('source') {
        sh 'git reset --hard $GWBT_COMMIT_AFTER'
      }
    } else {
       echo 'Skipped'
    }
  }
  stage('download dependencies') {
    if(doBuild) {
      dir('source') {
        sh 'yarn'
      }
    } else {
       echo 'Skipped'
    }
  }
  stage('build') {
    if(doBuild) {
      dir('source') {
        sh 'yarn build'
      }
    } else {
       echo 'Skipped'
    }
  }
  stage('deploy to nexus') {
    if(doBuild) {
      dir('source') {
        dir('dist') {
          // Convert e.g. 1.0.0 to 1.0.0-alpha.3434 => deployed to nexus
          packageVersion = sh(returnStdout: true, script: 'cat package.json | jq -r ".version"').trim()
          sh "npm version ${packageVersion}-alpha.${BUILD_NUMBER}"
          pipelineHelper.npmPublishToNexusRepository('cloukit')
        }
      }
    } else {
       echo 'Skipped'
    }
  }

  stage('archive') {
    if(doBuild) {
      dir('source') {
        dir('dist') {
          sh 'zip -r deploy.zip *'
          archiveArtifacts 'deploy.zip'
        }
      }
    } else {
       echo 'Skipped'
    }
  }
}

