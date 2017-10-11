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
  stage('test') {
    if(doBuild) {
      dir('source') {
        sh 'yarn test'
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
  stage('build demo') {
    if(doBuild && env.GWBT_REPO_NAME != "library-build-chain") {
      dir('source') {
        sh 'yarn build:demo'
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
  stage('deploy to npmjs') {
    if(env.GWBT_TAG) {
      dir('source') {
        dir('dist') {
          sh 'echo "//registry.npmjs.org/:_password=${NPMJS_PASSWORD}" > ~/.npmrc'
          sh 'echo "//registry.npmjs.org/:username=${NPMJS_USERNAME}" >> ~/.npmrc'
          sh 'echo "//registry.npmjs.org/:email=${NPMJS_EMAIL}" >> ~/.npmrc'
          sh 'echo "//registry.npmjs.org/:always-auth=false" >> ~/.npmrc'
          // reset package.json version back to release version
          sh "npm version ${GWBT_TAG}"
          sh 'npm --registry https://registry.npmjs.org/ --access public publish'
        }
      }
    } else {
       echo 'Skipped - no tag!'
    }
  }
  stage('deploy demo and compodoc') {
    if(env.GWBT_TAG && env.GWBT_REPO_NAME != "library-build-chain") {
      dir('source') {
        sh 'npm config set prefix /home/jenkins/.npmglobal && npm install -g node-deploy-essentials'
        sh '/home/jenkins/.npmglobal/bin/ndes deployToGitHubPages as "${GITHUB_COMMIT_USER}" withEmail "${GITHUB_COMMIT_EMAIL}" withGitHubAuthUsername ${GITHUB_COMMIT_USER} withGitHubAuthToken ${GITHUB_AUTH_TOKEN}  https://github.com/cloukit/${GWBT_REPO_NAME}.git fromSource documentation intoSubdirectory ${GWBT_TAG}/documentation'
        sh '/home/jenkins/.npmglobal/bin/ndes deployToGitHubPages as "${GITHUB_COMMIT_USER}" withEmail "${GITHUB_COMMIT_EMAIL}" withGitHubAuthUsername ${GITHUB_COMMIT_USER} withGitHubAuthToken ${GITHUB_AUTH_TOKEN}  https://github.com/cloukit/${GWBT_REPO_NAME}.git fromSource dist-demo/dist intoSubdirectory ${GWBT_TAG}/demo'
      }
    } else {
       echo 'Skipped - no tag!'
    }
  }
}
