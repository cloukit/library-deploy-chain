#!/bin/bash

#
# NOTE: ALL ENV-VARS MUST BE SET VIA -e ON DOCKER RUN!
#

set -e

#
# COPY FILES INTO CONTAINERS WORK DIR
#
cp -r /work/* /work-private/
cp -r /work/.gitignore /work-private/

#
# PREREQUISITES
#
cd /work-private/library-deploy-chain/
source ./jenkins-publish-github-release-asset-helper-1.0.0.sh

#
# INSTALL GLOBALS AND CONFIGURE PROXYS
#
mkdir /work-private/npm-global/
npm config set registry http://npm-proxy.home.codeclou.io/
export SASS_BINARY_SITE='http://github-proxy.home.codeclou.io/sass/node-sass/releases/download'
npm config set prefix '/work-private/npm-global/'
export PATH=$PATH:/work-private/npm-global/bin/
npm install -g node-deploy-essentials

#
# BUILD
#
cd /work-private/
yarn install
yarn build

#
# TEST
#

# synmlink node_modules
#ln -s ./build/node_modules ../node_modules
#yarn test:unit:single


#sed -i "s/___COMMIT___/$GWBT_COMMIT_AFTER/" ./src/app/app.component.ts
#sed -i "s/___BUILDSTAMP___/${BUILD_ID}/" ./src/app/app.component.ts

#
# PRE-PUBLISH
#
cd /work-private/dist
ls -lah
# Create zip without .git but with e.g. .htaccess (would need to be added manually)
if [ -d ".git" ]; then rm -rf .git; fi
zip -r dist.zip *
mv dist.zip /work/build-results/
chmod 777 /work/build-results/dist.zip
ls -lah
cd /work-private/

#
# PUBLISH
#
if [ -z "$GWBT_TAG" ]
then
  echo "NO TAG DETECTED. NO PUBLISH! EXIT!"
  exit 0
else
  echo "TAG DETECTED. CONTINUE PUBLISH!"
fi

#
# PUBLISH COMPODOC
#
if [ -d "/work-private/documentation" ]
then
  mv /work-private/documentation /work/build-results/
  chmod -R 777 /work/build-results/documentation/
  ndes deployToGitHubBranch \
    as "$GITHUB_COMMIT_USER" \
    withEmail "$GITHUB_COMMIT_EMAIL" \
    withGitHubAuthUsername "$GITHUB_AUTH_USER" \
    withGitHubAuthToken "$GITHUB_AUTH_TOKEN" \
    toRepository "https://github.com/cloukit/${GWBT_REPO_NAME}.git" \
    branch "gh-pages" \
    fromSource /work/build-results/documentation/ \
    intoSubdirectory component-doc/${GWBT_TAG}
else
  echo "SKIPPING COMPODOC SINCE THERE IS NO documentation FOLDER"
fi

# =============================================================
#
# PUBLISH dist.zip TO GITHUB.COM RELEASE
#
# =============================================================



#
# CREATE GITHUB RELEASE AND ADD dist.zip
#
package_version=$GWBT_TAG
release_id=-1
release_name=$GWBT_TAG
repository_owner="cloukit"
repository_name=$GWBT_REPO_NAME
branch_to_create_tag_from="master"

create_github_release_and_get_release_id \
    $repository_owner \
    $repository_name \
    $release_name \
    $branch_to_create_tag_from \
    release_id

upload_asset_to_github_release \
    $repository_owner \
    $repository_name \
    $release_name \
    $release_id \
    /work/build-results/ \
    dist.zip  \
    "application/octet-stream"


#
# PUBLISH dist/* TO NPMJS.COM
#

# values created by 'npm adduser'
echo "//registry.npmjs.org/:_password=${NPMJS_PASSWORD}" > ~/.npmrc
echo "//registry.npmjs.org/:username=${NPMJS_USERNAME}" >> ~/.npmrc
echo "//registry.npmjs.org/:email=${NPMJS_EMAIL}" >> ~/.npmrc
echo "//registry.npmjs.org/:always-auth=false" >> ~/.npmrc

cd /work-private/dist
npm --registry https://registry.npmjs.org/ --access public publish


# Refresh nopar mirror
echo ""
echo ">> REFRESHING NPM PROXY"
echo ""
COUNTER=0
while : ; do
    echo "."
    curl -s -o /dev/null -w "%{http_code}" "http://npm-proxy.home.codeclou.io/-/package/@cloukit/${GWBT_REPO_NAME}/refresh"
    sleep 5s
    LATEST_VERSION_IN_NPM_MIRROR=$(curl --silent  "http://npm-proxy.home.codeclou.io/@cloukit%2f${GWBT_REPO_NAME}" | jq -r .\"dist-tags\".latest)
    [[ "$GWBT_TAG" == "$LATEST_VERSION_IN_NPM_MIRROR" ]] || break
    let COUNTER=COUNTER+1
    if [ $COUNTER -gt 30 ]
    then
      echo "break infitie loop!"
      break
    fi
done
