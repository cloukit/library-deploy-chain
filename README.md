[![](https://cloukit.github.io/assets/images/cloukit-banner-github.svg?v3)](https://cloukit.github.io/)

# library-deploy-chain

Common code to deploy cloukit modules to npm and github releases

----


&nbsp;

### Usage

Put this into each modules `jenkins.sh` to trigger a dockerized build inside Jenkins.

```bash
#!/bin/bash

# BUILD TRIGGERED BY: https://github.com/codeclou/jenkins-github-webhook-build-trigger-plugin
set -e
git clone https://github.com/cloukit/library-deploy-chain.git library-deploy-chain
cd library-deploy-chain
bash jenkins.sh
```

This will trigger a build via the modules `yarn build` script,
which triggers `library-build-chain`.

-----

&nbsp;

## License

[MIT](./LICENSE) © [Bernhard Grünewaldt](https://github.com/clouless)
