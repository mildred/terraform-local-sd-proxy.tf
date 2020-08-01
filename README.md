sd-proxy.tf
===========

Manages boilerplace necessary to handle systemd socket activation proxy.

Using [force-bind] to force using socket activation might be a better idea. Also, a proxy that can handle multiple sockets and the haproxy PROXY protocol might be nice.

[force-bind]: https://github.com/mildred/force-bind-seccomp

