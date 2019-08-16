# thrift-core-with-external-ssh

docker build -t <tag> --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" --build-arg SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" .
  
  will need specific rpc directory with composer.json and requirements
