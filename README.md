[![](https://cloukit.github.io/assets/images/cloukit-banner-github.svg?v3)](https://cloukit.github.io/)

# library-deploy-chain

Common code to deploy cloukit modules to npm and github releases

----


&nbsp;

### Usage

Put this into each modules `Jenkinsfile` to trigger a dockerized build inside Jenkins.

```bash
node {
  if (env.GWBT_REPO_FULL_NAME) {
      sh 'curl -H "Authorization: token ${GITHUB_AUTH_TOKEN}" -H "Accept: application/vnd.github.v3.raw" -o Jenkinsfile -L https://api.github.com/repos/cloukit/library-deploy-chain/contents/Jenkinsfile'
      load('./Jenkinsfile')
  } else {
      echo "manual starts not allowed!"
  }
}
```

-----

&nbsp;

## License

[MIT](./LICENSE) © [Bernhard Grünewaldt](https://github.com/clouless)
