# Docker image for ARM (Raspberry Pi)
This Docker image provides the Open Source edition of the Kong Gateway (see https://github.com/Kong/kong) for ARM based architectures. It has been tested and deployed with some Raspberry Pi 3+

## Prerequesites
When compiling this image on a non ARM machine you need (next to a Docker installation) to have QEMU <https://www.qemu.org> being installed and activated. Luckily this is extremely easy, just do

```
docker run --rm --privileged multiarch/qemu-user-static:register --reset
```
  
See <https://blog.hypriot.com/post/setup-simple-ci-pipeline-for-arm-images/> for more details on creating ARM images on non ARM platforms.

## Usage
Well, it's a Dockerfile and an docker-entrypoint.sh, so just do

```
docker build . 
```
  
to get your image in your local Docker registry. **Compilation will take very long** (due to the use of QEMU) but you can find a compiled version on Dockerhub *svenwal/kong-arm* at <https://cloud.docker.com/repository/docker/svenwal/kong-arm>

## Testing
So far the only tests have been on a Kubernetes cluster on some Raspberry Pi 3+ 
