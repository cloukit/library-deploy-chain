[![](https://cloukit.github.io/assets/images/cloukit-banner-github.svg?v3)](https://cloukit.github.io/)

### :bangbang: DEPRECATED AND ARCHIVED

# library-deploy-chain

Common code to deploy cloukit modules to npm and github releases

----


&nbsp;

### Usage

Put this into each pipeline Jenkins Job to trigger a dockerized build inside Jenkins.

```bash
node {
  wrap([$class: 'HideSecretEnvVarsBuildWrapper']) {
      if (env.GWBT_BRANCH == 'gh-pages') {
        echo "NOT BUILDING GH-PAGES BRANCH"
      } else if (env.GWBT_REPO_FULL_NAME) {
        // ALWAYS LOAD JENKINSFILE FROM MASTER !!! TO AVOID INJECTS BY PULL REQUESTS !!!
        sh 'curl -H "Authorization: token ${SECRET_GITHUB_AUTH_TOKEN}" -H "Accept: application/vnd.github.v3.raw" -o Jenkinsfile -L https://api.github.com/repos/cloukit/library-deploy-chain/contents/Jenkinsfile'
        load('./Jenkinsfile')
      } else {
        echo "manual starts not allowed!"
      }
  }
}

```

 * Master Branch pushes will be deployed to Nexus as alpha versions e.g. 1.1.0-alpha.6
 * Tag pushes will be deployed to npmjs as release versions e.g. 1.1.0

-----

&nbsp;

## License

[MIT](./LICENSE) © [Bernhard Grünewaldt](https://github.com/clouless)
