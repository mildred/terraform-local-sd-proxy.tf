variable "unit_name" {
}

variable "host4" {
  default = "$${HOSTADDR4}"
}

variable "host6" {
  default = "[$${HOSTADDR6}]"
}

variable "service_host4" {
  default = ""
}

variable "service_host6" {
  default = ""
}

variable "proxy_host4" {
  default = ""
}

variable "proxy_host6" {
  default = ""
}

variable "ports" {
}

locals {
  proxy_host4 = var.proxy_host4 != "" ? var.proxy_host4 : var.host4
  proxy_host6 = var.proxy_host6 != "" ? var.proxy_host6 : var.host4
  service_host4 = var.service_host4 != "" ? var.service_host4 : var.host4
  service_host6 = var.service_host6 != "" ? var.service_host6 : var.host4
}

data "template_file" "exec_start" {
  for_each = var.ports
  vars = {
    portname   = "${each.key}"
    listenport = each.value[0]
    toport     = each.value[1]
    host       = lookup({4=local.proxy_host4, 6=local.proxy_host6}, substr(each.key, -1, 1), local.proxy_host4)
    to_host    = lookup({4=local.service_host4, 6=local.service_host6}, substr(each.key, -1, 1), local.service_host4)
  }
  template = <<EOF
ExecStart=/usr/bin/systemd-run \
  --unit=${var.unit_name}-proxy-$${portname} \
  --property=Requires=${var.unit_name}.service \
  --property=After=${var.unit_name}.service \
  --socket-property=ListenStream=$${host}:$${listenport} \
  /lib/systemd/systemd-socket-proxyd "$${to_host}:$${toport}"
EOF
}

data "template_file" "exec_stop" {
  for_each = var.ports
  vars = {
    portname = "${each.key}"
  }
  template = <<EOF
  ${var.unit_name}-proxy-$${portname}.socket \
EOF
}

output "service" {
  value = <<EOF
Type=oneshot
RemainAfterExit=yes
${join("", values(data.template_file.exec_start).*.rendered)}
ExecStop=/usr/bin/systemctl stop \
${join("", values(data.template_file.exec_stop).*.rendered)}

EOF
}
