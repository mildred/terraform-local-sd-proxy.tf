sd-proxy.tf
===========

Manages boilerplace necessary to handle systemd socket activation proxy.

Generates a service unit that when started consumes no resources and generates
on the fly sockets units for multiple connections backed by a systemd proxy
service that is socket-activated.

Using [force-bind] to force using socket activation might be a better idea.
Also, a proxy that can handle multiple sockets and the haproxy PROXY protocol
might be nice.

Example usage
-------------

This module helps you creating systemd proxy units with multiple connections
bound using dynamic addresses. Example:

```hcl

locals {
  unit_name = "my-service"
}

module "my_service_proxy_service" {
  source = ".../sd-proxy.tf"
  unit_name = "${local.unit_name}"
  host4 = "$${HOST_my_service4}"
  host6 = "[$${HOST_my_service6}]"
  ports = {
    http4 = [80, 10080]
    http6 = [80, 10080]
  }
}

resource "sys_file" "my_service_proxy_service" {
  filename = "/etc/systemd/system/${local.unit_name}-proxy.service"
  content = <<EOF
[Unit]
Requires=addr@${local.unit_name}.service
After=addr@${local.unit_name}.service

[Service]
EnvironmentFile=/run/addr/${local.unit_name}.env
${module.my_service_proxy_service.service}

[Install]
WantedBy=multi-user.target

EOF
}

```

Variables
---------

- `unit_name`: Name of your unit without the `.service` suffix that provides the
  service

- `host4`, `host6`: Hostnames that will serve as default for `proxy_host4`,
  `service_host4`, `proxy_host6` and `service_host6`. If the service and the
  proxy should listen to the same address, it is easier to set the `host4` and
  `host6` variables.

  Defaults to `${HOSTADDR4}` and `[${HOSTADDR6}]` so it can be used directly
  with an `addr@.service` unit.

- `proxy_host4`, `proxy_host6`: Hostnames the proxy service should listen to for
  IPv4 and IPv6 ports. Will be expanded by systemd. Defaults to the value of
  `host4` and `host6`.

- `service_host4`, `service_host6`: Hostnames the proxy will connect to for the
  backend `${unit_name}.service` for IPv4 and IPv6 ports. Will be expanded by
  systemd. Defaults to the value of `host4` and `host6`.

- `ports`: Hash containing the ports to create a proxy for. Multiple ports can
  be specified. Hash key must be a port name ending with either `4` or `6`
  depending on IPv4/IPv6.

  Hash value is an array of two integers. The first integer is the port number
  the proxy will listen to, the second is the port the service
  `${unit_name}.service` is listening to.

  A socket and service unit are created for each declared port. Their name is
  `${unit_name}-proxy-${port_name}.socket` and
  `${unit_name}-proxy-${port_name}.service`

Outputs
-------

- `service`: Systemd unit code to put in the `[Service]` section to generate a
  proxy service unit. it is recommended that the service unit is called
  `${unit_name}-proxy.service` as it will proxy `${unit_name}.service`

Example of using force-bind instead of a proxy
----------------------------------------------


[force-bind]: https://github.com/mildred/force-bind-seccomp

