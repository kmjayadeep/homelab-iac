# K3s setup
Adjust commands in makefile to setup only one of the nodes

when istalling on agent, make sure to update secrets/secret-k3s-token
get it by running on the master node:

```
k3s token create
```
