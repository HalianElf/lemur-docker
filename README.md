# halianelf/lemur

Feel free to submit Pull Requests and report any Issues that you may have found.

## Lemur + CFSSL

[Lemur](https://github.com/Netflix/lemur) manages TLS certificate creation. While not able to issue certificates itself, 
Lemur acts as a broker between CAs and environments providing a central portal for developers to issue TLS certificates 
with 'sane' defaults.

[CFSSL](https://github.com/cloudflare/cfssl) is CloudFlare's PKI/TLS swiss army knife. It is both a command line tool and 
an HTTP API server for signing, verifying, and bundling TLS certificates.

## Usage
```
docker create \
  --name=lemur \
  -v <path to config>:/config \
  -v <path to data>:/data \
  -e PGID=<gid> -e PUID=<uid>  \
  -p 80:80 \
  halianelf/lemur
```

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the 
container side. For example with a port -p external:internal - what this shows is the port mapping from internal to external 
of the container. So `-p 8080:80` would expose port 80 from inside the container to be accessible from the host's IP on port 
8080 and `http://192.168.x.x:8080` would show you what's running INSIDE the container on port 80.

* `-p 80` - The port(s)
* `-v /config` - Mapping the config files for Lemur and CFSSL
* `-v /data` - Mapping for the Postgres DB data
* `-e PGID` Used for GroupID - see below for explanation
* `-e PUID` Used for UserID - see below for explanation

### User / Group Identifiers

Sometimes when using data volumes (`-v` flags) permissions issues can arise between the host OS and the container. We avoid 
this issue by allowing you to specify the user `PUID` and group `PGID`. Ensure the data volume directory on the host is owned 
by the same user you specify and it will "just work" ™.

In this instance `PUID=1001` and `PGID=1001`. To find yours use `id user` as below:

```
  $ id <dockeruser>
    uid=1001(dockeruser) gid=1001(dockergroup) groups=1001(dockergroup)
```

## Setting up the application

After the initial start up, there will be some template files in `/config/cfssl`. If you edit these and remove the `.tmpl` and then 
restart the container, it will generate the certificates with the information you put in. If you want to change the length of the 
intermediate certificate, change it in the `root_to_intermediate_ca.json` file.

CFSSL can't actually use any of the parameters for the certificate signing that you can set in Lemur (at least currently) so whatever 
is set as the default in `cfssl_config.json` is what it will use. The config that comes with this is a server certificate with a 3 
year expiration. Feel free to edit this to fit your needs.

For Lemur, the config is in `/config/lemur/lemur.conf.py`. This file is mostly the default with some Digicert stuff added and the 
CFSSL config stuff added. Generating the certs with the template files like explained in the first paragraph will add them to the 
file as well. This file also can and should be editted to fit your needs. Read over the 
[Lemur Docs](https://lemur.readthedocs.io/en/latest/administration.html) for more information on settings and what you can do with this.

The Lemur web interface is accessible on whatever port you mapped for the container. The default credentials are `lemur` and `password`.
This can be changed in the web interface after logging in. You will need to add CFSSL as an authority after you have your certs created.
For more information on this take a look at the "Create certificates using CFSSL" section on
[here](https://www.howtoforge.com/tutorial/integration-of-cfssl-with-the-lemur-certificate-manager/).

## Building the Container

If you wish to build this yourself, you will need to pull CFSSL for the intermediate container.

## Info

* Shell access whilst the container is running: `docker exec -it lemur /bin/bash`
* To monitor the logs of the container in realtime: `docker logs -f lemur`
