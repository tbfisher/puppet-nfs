class nfs::server () {

  package { [
      'nfs-kernel-server',
      'nfs-common',
      'rpcbind',
    ] :
    ensure => 'installed'
  }

  service { "nfs-kernel-server":
    enable => true,
    ensure => running,
    require => Package['nfs-kernel-server'],
  }
  if $lsbdistid != 'Debian' {
    service { "statd":
      enable => true,
      ensure => running,
      require => Package['nfs-kernel-server'],
    }
  }

  # By default, several of NFS’s supporting services choose random ports to
  # run on at start-time. If firewall enabled, restrict nfs services to
  # specific ports and open those ports.
  #
  # Note I'm opening from anywhere, for production use should read the
  # individual nfs::export declarations and match the hostname field for each
  # export.
  #
  # http://bryanw.tk/2012/specify-nfs-ports-ubuntu-linux/
  if defined(Class['ufw']) {

    file_line { "/etc/default/nfs-common STATDOPTS":
      path => "/etc/default/nfs-common",
      match => '^STATDOPTS=',
      line => 'STATDOPTS="--port 4000"',
      notify => Service['statd'],
    }

    file { "/etc/modprobe.d/options.conf":
      ensure => present,
    } ->
    file_line { "/etc/modprobe.d/options.conf options lockd nlm_udpport":
      path => "/etc/modprobe.d/options.conf",
      match => '^options lockd nlm_udpport=',
      line => 'options lockd nlm_udpport=4001 nlm_tcpport=4001',
      notify => Service['nfs-kernel-server'],
    } ->
    file_line { "/etc/modules lockd":
      path => "/etc/modules",
      line => 'lockd',
    } ~>
    exec { "modprobe lockd":
      refreshonly => true,
    }

    file_line { "/etc/default/nfs-kernel-server RPCMOUNTDOPTS":
      path => "/etc/default/nfs-kernel-server",
      match => '^RPCMOUNTDOPTS=',
      line => 'RPCMOUNTDOPTS="--manage-gids -p 4002"',
      notify => Service['nfs-kernel-server'],
    }

    $ports = {
      "allow any to 111" => { port => 111 },
      "allow any to 4000" => { port => 4000 },
      "allow any to 4001" => { port => 4001 },
      "allow any to 2049" => { port => 2049 },
      "allow any to 4002" => { port => 4002 },
    }
    create_resources(ufw::allow, $ports, { ip => 'any', proto => 'any' })

  }
}

# - clients
#   hash of nfs clients keyed on directory.
#   See exports(5).
define nfs::export (
  $clients,
) {

  include ::nfs::server

  $clients_string = join($clients, ' ')

  file_line { "/etc/exports ${title}":
    path => '/etc/exports',
    line => "${title} ${clients_string} # puppet nfs::export",
    match => "^${title} .*# puppet nfs::export",
    notify => Service['nfs-kernel-server'],
    require => Package['nfs-kernel-server'],
  }
}
