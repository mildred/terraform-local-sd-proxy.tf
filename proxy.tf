variable "unit_name" {
}

variable "host4" {
}

variable "host6" {
}

variable "ports" {
}

data "template_file" "exec_start" {
  for_each = var.ports
  vars = {
    portname   = "${each.key}"
    listenport = each.value[0]
    toport     = each.value[1]
    host       = lookup({4=var.host4, 6=var.host6}, substr(each.key, -1, 1), var.host4)
  }
  template = <<EOF
ExecStart=/usr/bin/systemd-run \
  --unit=${var.unit_name}-proxy-$${portname} \
  --property=Requires=${var.unit_name}.service \
  --property=After=${var.unit_name}.service \
  --socket-property=ListenStream=$${host}:$${listenport} \
  /lib/systemd/systemd-socket-proxyd "$${host}:$${toport}"
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
