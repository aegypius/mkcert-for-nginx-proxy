# mkcert for nginx-proxy

mkcert-for-nginx-proxy is a lightweight companion container for the [jwilder/nginx-proxy].
It's heavily inspired by [JrCs/letsencrypt-nginx-proxy-companion] and it allows the creation/renewal
of self-signed certificate with a root certificate authority.

### Features

- Automatic creation/renewal of Self-Signed Certificates using original nginx-proxy container
- Support creation of Multi-Domain ([SAN](https://www.digicert.com/subject-alternative-name.htm])) certificates
- Work with all versions of docker

### Usage

Here is an example of  a docker-compose file that should work with jwilder/nginx-proxy:

```yaml
version: '3.2'

networks:
  proxy:
    driver: bridge

services:

  mkcert:
    image: aegypius/mkcert-for-nginx-proxy
    restart: unless-stopped
    volumes:
    - ssl-certs:/app/certs:rw
    - ~/.mozilla/firefox:/root/.mozilla/firefox:rw
    - ~/.pki/nssdb:/root/.pki/nssdb:rw
    - ${CA_STORE:-/usr/local/share/ca-certificates}:/usr/local/share/ca-certificates
    - /var/run/docker.sock:/var/run/docker.sock:ro

  proxy:
    image: jwilder/nginx-proxy
    labels:
      com.github.aegypius.mkcert-for-nginx-proxy.nginx_proxy: ''
    networks:
      proxy: {}
    ports:
    - published: 80
      target: 80
    - published: 443
      target: 443
    restart: unless-stopped
    volumes:
    - ssl-certs:/etc/nginx/certs:ro
    - /var/run/docker.sock:/tmp/docker.sock:ro

volumes:
  ssl-certs: {}
```

You need to set a CA_STORE environment variable  according to your distribution :

#### For Ubuntu / Debian:

```shell
docker-compose up
sudo update-ca-certificates
```

#### For Arch / Manjaro:

```shell
echo 'CA_STORE=/etc/ca-certificates/trust-source/anchors' >> .env
docker-compose up
sudo trust extract-compat
```

#### For Fedora / RHEL / CentOS:

```shell
echo 'CA_STORE=/etc/pki/ca-trust/source/anchors' >> .env
docker-compose up
sudo update-ca-trust extract
```

##### For Gentoo:

```shell
echo 'CA_STORE=/etc/ssl/certs' >> .env
docker-compose up
sudo update-ca-certificates
```

Restart your browsers !

### Related projects

- [FiloSottile/mkcert]
- [JrCS/letsencrypt-nginx-proxy-companion]
- [jwilder/docker-gen]
- [jwilder/nginx-proxy]

[FiloSottile/mkcert]: https://github.com/FiloSottile/FiloSottile/mkcert
[JrCs/letsencrypt-nginx-proxy-companion]: https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion
[jwilder/nginx-proxy]: https://github.com/jwilder/nginx-proxy
[jwilder/docker-gen]: https://github.com/jwilder/docker-gen
