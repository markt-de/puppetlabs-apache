# frozen_string_literal: true

require 'spec_helper'

describe 'apache::mod::itk', type: :class do
  let :pre_condition do
    'class { "apache": mpm_module => false, }'
  end

  context 'on a Debian OS' do
    include_examples 'Debian 11'

    it { is_expected.to contain_class('apache::params') }
    it { is_expected.not_to contain_apache__mod('itk') }
    it { is_expected.to contain_file('/etc/apache2/mods-available/itk.conf').with_ensure('file') }
    it { is_expected.to contain_file('/etc/apache2/mods-enabled/itk.conf').with_ensure('link') }

    context 'with Apache version < 2.4' do
      let :params do
        {
          apache_version: '2.2',
        }
      end

      it { is_expected.not_to contain_file('/etc/apache2/mods-available/itk.load') }
      it { is_expected.not_to contain_file('/etc/apache2/mods-enabled/itk.load') }

      it { is_expected.to contain_package('apache2-mpm-itk') }
    end
    context 'with Apache version < 2.4 with enablecapabilities set' do
      let :params do
        {
          apache_version: '2.2',
          enablecapabilities: true,
        }
      end

      it { is_expected.not_to contain_file('/etc/apache2/mods-available/itk.conf').with_content(%r{EnableCapabilities}) }
    end

    context 'with Apache version >= 2.4' do
      let :pre_condition do
        'class { "apache": mpm_module => prefork, }'
      end

      let :params do
        {
          apache_version: '2.4',
        }
      end

      it {
        is_expected.to contain_file('/etc/apache2/mods-available/itk.load').with('ensure' => 'file',
                                                                                 'content' => "LoadModule mpm_itk_module /usr/lib/apache2/modules/mod_mpm_itk.so\n")
      }
      it { is_expected.to contain_file('/etc/apache2/mods-enabled/itk.load').with_ensure('link') }
    end
    context 'with Apache version >= 2.4 with enablecapabilities not set' do
      let :pre_condition do
        'class { "apache": mpm_module => prefork, }'
      end
      let :params do
        {
          apache_version: '2.4',
        }
      end

      it { is_expected.not_to contain_file('/etc/apache2/mods-available/itk.conf').with_content(%r{EnableCapabilities}) }
    end
  end

  context 'on a RedHat OS' do
    include_examples 'RedHat 8'

    it { is_expected.to contain_class('apache::params') }
    it { is_expected.not_to contain_apache__mod('itk') }
    it { is_expected.to contain_file('/etc/httpd/conf.modules.d/itk.conf').with_ensure('file') }
    it { is_expected.to contain_package('httpd-itk') }

    context 'with Apache version < 2.4' do
      let :params do
        {
          apache_version: '2.2',
        }
      end

      it {
        is_expected.to contain_file_line('/etc/sysconfig/httpd itk enable').with('require' => 'Package[httpd]')
      }
    end
    context 'with Apache version < 2.4 with enablecapabilities set' do
      let :params do
        {
          apache_version: '2.2',
          enablecapabilities: 'On',
        }
      end

      it { is_expected.not_to contain_file('/etc/httpd/conf.d/itk.conf').with_content(%r{EnableCapabilities}) }
    end

    context 'with Apache version >= 2.4' do
      let :pre_condition do
        'class { "apache": mpm_module => prefork, }'
      end

      let :params do
        {
          apache_version: '2.4',
        }
      end

      it {
        is_expected.to contain_file('/etc/httpd/conf.modules.d/itk.load').with('ensure' => 'file',
                                                                       'content' => "LoadModule mpm_itk_module modules/mod_mpm_itk.so\n")
      }
    end
    context 'with Apache version >= 2.4 with enablecapabilities set' do
      let :pre_condition do
        'class { "apache": mpm_module => prefork, }'
      end

      let :params do
        {
          apache_version: '2.4',
          enablecapabilities: false,
        }
      end

      it { is_expected.to contain_file('/etc/httpd/conf.modules.d/itk.conf').with_content(%r{EnableCapabilities  Off}) }
    end
  end
  context 'on a FreeBSD OS' do
    let :pre_condition do
      'class { "apache": mpm_module => false, }'
    end

    include_examples 'FreeBSD 10'
    # TODO: fact mpm_module itk?

    it { is_expected.to contain_class('apache::params') }
    it { is_expected.not_to contain_apache__mod('itk') }
    it { is_expected.to contain_file('/usr/local/etc/apache24/Modules/itk.conf').with_ensure('file') }
    it { is_expected.to contain_package('www/mod_mpm_itk') }

    context 'with Apache version < 2.4 with enablecapabilities not set' do
      let :params do
        {
          apache_version: '2.2',
        }
      end

      it { is_expected.not_to contain_file('/usr/local/etc/apache24/Modules/itk.conf').with_content(%r{EnableCapabilities}) }
    end

    context 'with Apache version >= 2.4 with enablecapabilities set' do
      let :params do
        {
          apache_version: '2.4',
          enablecapabilities: true,
        }
      end

      it { is_expected.to contain_file('/usr/local/etc/apache24/Modules/itk.conf').with_content(%r{EnableCapabilities  On}) }
    end
  end
end
