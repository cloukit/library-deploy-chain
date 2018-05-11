sh 'curl -sSLko pipeline-helper.groovy ${K8S_INFRASTRUCTURE_BASE_URL}pipeline-helper/pipeline-helper.groovy?v2'
def pipelineHelper = load("./pipeline-helper.groovy")
def doBuild = true
def packageVersion = 'x.x.x'
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
      if(fileExists("source")) {
        sh 'rm -rf ./source'
      }
      sh 'git clone --single-branch --branch $GWBT_BRANCH$GWBT_TAG https://${GITHUB_AUTH_TOKEN}@github.com/${GWBT_REPO_FULL_NAME}.git source'
      dir ('source') {
        sh 'git reset --hard $GWBT_COMMIT_AFTER'
      }
    } else {
       echo 'Skipped'
    }
  }
  stage('fetch version from library') {
    if(doBuild) {
      dir ('source') {
        packageVersion = sh(returnStdout: true, script: 'cat projects/cloukit/' + env.GWBT_REPO_NAME + '/package.json | jq -r ".version"').trim()
        echo 'VERSION: ' + packageVersion;
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
  stage('build library') {
    if(doBuild) {
      dir('source') {
        sh 'yarn build @cloukit/' + env.GWBT_REPO_NAME + ' --prod'
      }
    } else {
       echo 'Skipped'
    }
  }
  stage('build compodoc') {
    if(doBuild) {
      dir('source') {
        echo('>> ==============');
        echo('>> CREATING COMPODOC');
        echo('>> ==============');
        // INSTALL SPECIFIC VERSION
        sh 'yarn add @compodoc/compodoc@1.1.2 --dev'
        // CDN URL WHERE WE HAVE DEPLOYED FONTS,JS,CSS CENTRALLY
        cdnUrl = 'https://cloukit.github.io/compodoc-theme/theme/1.0.0-beta.10'
        // PATCH JS CDN URLS
        sh 'sed -i -e \'s@src="[^"]*js/@src="' + cdnUrl + '/dist/js/@g\' ./node_modules/compodoc/src/templates/page.hbs'
        sh 'sed -i -e \'s@src="[^"]*js/@src="' + cdnUrl + '/dist/js/@g\' ./node_modules/compodoc/src/templates/partials/component.hbs'
        sh 'sed -i -e \'s@src="[^"]*js/@src="' + cdnUrl + '/dist/js/@g\' ./node_modules/compodoc/src/templates/partials/module.hbs'
        sh 'sed -i -e \'s@src="[^"]*js/@src="' + cdnUrl + '/dist/js/@g\' ./node_modules/compodoc/src/templates/partials/routes.hbs'
        sh 'sed -i -e \'s@src="[^"]*js/@src="' + cdnUrl + '/dist/js/@g\' ./node_modules/compodoc/src/templates/partials/overview.hbs'
        // PATCH OTHER CDN URLS
        sh 'sed -i -e \'s@href="[^"]*styles/style.css@href="' + cdnUrl + '/style.css@g\' ./node_modules/compodoc/src/templates/page.hbs'
        sh 'sed -i -e \'s@href="[^"]*images/favicon.ico@href="' + cdnUrl + '/images/favicon.ico@g\' ./node_modules/compodoc/src/templates/page.hbs'
        sh 'sed -i -e \'s@src="[^"]*images/compodoc-vectorise.svg@src="' + cdnUrl + '/images/compodoc-logo.svg@g\' ./node_modules/compodoc/src/templates/partials/menu.hbs'
        // Build CompoDoc
        sh './node_modules/compodoc/bin/index-cli.js --tsconfig tsconfig.json --disableCoverage --disablePrivateOrInternalSupport --name "' + env.GWBT_REPO_NAME + ' v' + packageVersion + '" src'
        // Cleanup - we do not want to deploy these files with every release!
        if(fileExists("./documentation/fonts/")) { sh 'rm -rf ./documentation/fonts/' }
        if(fileExists("./documentation/images/")) { sh 'rm -rf ./documentation/images/' }
        if(fileExists("./documentation/styles/")) { sh 'rm -rf ./documentation/styles/' }
        if(fileExists("./documentation/js/")) { sh 'rm -rf ./documentation/js/' }
        // ARCHIVE
        sh 'zip -r compodoc.zip documentation'
        archiveArtifacts artifacts: 'compodoc.zip', fingerprint: true
      }
    } else {
       echo 'Skipped'
    }
  }
  stage('build demo') {
    if(doBuild) {
      dir('source') {
        sh 'yarn pre'
        sh 'yarn build ' + env.GWBT_REPO_NAME + '-demo --base-href /' + env.GWBT_REPO_NAME + '/1.7.0/demo/ --prod'
        dir('dist') {
          sh 'zip -r demo.zip ' + env.GWBT_REPO_NAME + '-demo'
          archiveArtifacts artifacts: 'demo.zip', fingerprint: true
        }
      }
    } else {
       echo 'Skipped'
    }
  }
  stage('deploy to nexus') {
    if(doBuild) {
      dir('source') {
        dir('dist/cloukit/' + env.GWBT_REPO_NAME) {
          // Convert e.g. 1.0.0 to 1.0.0-alpha.3434 => deployed to nexus
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
        dir('dist/cloukit/' + env.GWBT_REPO_NAME) {
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
    if(env.GWBT_TAG) {
      sh 'git config --global user.name ${GITHUB_COMMIT_USER}'
      sh 'git config --global user.email ${GITHUB_COMMIT_EMAIL}'
      sh 'git config --global push.default simple'
      sh 'git clone --single-branch --branch gh-pages https://${GITHUB_AUTH_TOKEN}@github.com/cloukit/${GWBT_REPO_NAME}.git gh-pages'
      dir('gh-pages') {
        sh 'mkdir ${GWBT_TAG}'
        sh 'cp -r ../source/documentation ${GWBT_TAG}/documentation'
        sh 'cp -r ../source/dist/' + env.GWBT_REPO_NAME + '-demo ${GWBT_TAG}/demo'
        sh 'git add . -A'
        sh 'git commit -m "deploy via ci"'
        sh 'git push'
      }
    } else {
       echo 'Skipped - no tag!'
    }
  }
}
