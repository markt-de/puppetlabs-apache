# @summary
#   Installs and manages the MPM `worker`.
#
# @param startservers
#   The number of child server processes created on startup
#
# @param maxclients
#   The max number of simultaneous requests that will be served.
#   This is the old name and is still supported. The new name is
#   MaxRequestWorkers as of 2.3.13.
#   If maxrequestworkers is set, this value is ignored.
#
# @param minsparethreads
#   Minimum number of idle threads to handle request spikes.
#
# @param maxsparethreads
#   Maximum number of idle threads.
#
# @param threadsperchild
#   The number of threads created by each child process.
#
# @param maxrequestsperchild
#   Limit on the number of connectiojns an individual child server
#   process will handle. This is the old name and is still supported. The new
#   name is MaxConnectionsPerChild as of 2.3.9+.
#
# @param serverlimit
#   With worker, use this directive only if your MaxRequestWorkers
#   and ThreadsPerChild settings require more than 16 server processes
#   (default). Do not set the value of this directive any higher than the
#   number of server processes required by what you may want for
#   MaxRequestWorkers and ThreadsPerChild.
#
# @param threadlimit
#   This directive sets the maximum configured value for
#   ThreadsPerChild for the lifetime of the Apache httpd process.
#
# @param listenbacklog
#    Maximum length of the queue of pending connections.
#
# @param apache_version
#   Used to verify that the Apache version you have requested is compatible with the module.
#
# @param maxrequestworkers
#   Maximum number of connections that will be processed simultaneously
#   if set, maxclients is ignored
#
# @see https://httpd.apache.org/docs/current/mod/worker.html for additional documentation.
#
class apache::mod::worker (
  Integer $startservers            = 2,
  Integer $maxclients              = 150,
  Integer $minsparethreads         = 25,
  Integer $maxsparethreads         = 75,
  Integer $threadsperchild         = 25,
  Integer $maxrequestsperchild     = 0,
  Integer $serverlimit             = 25,
  Integer $threadlimit             = 64,
  Integer $listenbacklog           = 511,
  Optional[String] $apache_version = undef,
  Optional[Integer] $maxrequestworkers = undef,
) {
  include apache
  $_apache_version = pick($apache_version, $apache::apache_version)

  if defined(Class['apache::mod::event']) {
    fail('May not include both apache::mod::worker and apache::mod::event on the same node')
  }
  if defined(Class['apache::mod::itk']) {
    fail('May not include both apache::mod::worker and apache::mod::itk on the same node')
  }
  if defined(Class['apache::mod::peruser']) {
    fail('May not include both apache::mod::worker and apache::mod::peruser on the same node')
  }
  if defined(Class['apache::mod::prefork']) {
    fail('May not include both apache::mod::worker and apache::mod::prefork on the same node')
  }
  File {
    owner => 'root',
    group => $apache::params::root_group,
    mode  => $apache::file_mode,
  }

  # Template uses:
  # - $startservers
  # - $maxclients
  # - $minsparethreads
  # - $maxsparethreads
  # - $threadsperchild
  # - $maxrequestsperchild
  # - $serverlimit
  # - $threadLimit
  # - $listenbacklog
  file { "${apache::mod_dir}/worker.conf":
    ensure  => file,
    content => template('apache/mod/worker.conf.erb'),
    require => Exec["mkdir ${apache::mod_dir}"],
    before  => File[$apache::mod_dir],
    notify  => Class['apache::service'],
  }

  case $facts['os']['family'] {
    'redhat': {
      if versioncmp($_apache_version, '2.4') >= 0 {
        ::apache::mpm { 'worker':
          apache_version => $_apache_version,
        }
      }
      else {
        file_line { '/etc/sysconfig/httpd worker enable':
          ensure  => present,
          path    => '/etc/sysconfig/httpd',
          line    => 'HTTPD=/usr/sbin/httpd.worker',
          match   => '#?HTTPD=/usr/sbin/httpd.worker',
          require => Package['httpd'],
          notify  => Class['apache::service'],
        }
      }
    }

    'debian', 'freebsd': {
      ::apache::mpm { 'worker':
        apache_version => $_apache_version,
      }
    }
    'Suse': {
      ::apache::mpm { 'worker':
        apache_version => $apache_version,
        lib_path       => '/usr/lib64/apache2-worker',
      }
    }

    'gentoo': {
      ::portage::makeconf { 'apache2_mpms':
        content => 'worker',
      }
    }
    default: {
      fail("Unsupported osfamily ${$facts['os']['family']}")
    }
  }
}
