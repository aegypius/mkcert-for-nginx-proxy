# mkcert for nginx-proxy

mkcert-for-nginx-proxy is a lightweight companion container for the [jwilder/nginx-proxy].
It's heavily inspired by [JrCs/letsencrypt-nginx-proxy-companion] and it allows the creation/renewal
of self-signed certificate with a root certificate authority.

### Features

- Automatic creation/renewal of Self-Signed Certificates using original nginx-proxy container
- Support creation of Multi-Domain ([SAN](https://www.digicert.com/subject-alternative-name.htm])) certificates
- Work with all versions of docker

### Usage

(Documentation pending... sorry !)

### Related projects

- [FiloSottile/mkcert]
- [JrCS/letsencrypt-nginx-proxy-companion]
- [jwilder/docker-gen]
- [jwilder/nginx-proxy]

[FiloSottile/mkcert]: https://github.com/FiloSottile/FiloSottile/mkcert
[JrCs/letsencrypt-nginx-proxy-companion]: https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion
[jwilder/nginx-proxy]: https://github.com/jwilder/nginx-proxy
[jwilder/docker-gen]: https://github.com/jwilder/docker-gen
