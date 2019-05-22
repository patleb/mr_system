sun.install "sysstat"

case "$OS" in
ubuntu)
  sun.backup_compile '/etc/default/sysstat'
;;
centos)
  sun.backup_compare '/etc/sysconfig/sysstat'
;;
esac

systemctl enable sysstat
systemctl start sysstat
