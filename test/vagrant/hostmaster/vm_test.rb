require 'test/unit'
require "mocha"
require 'vagrant/hostmaster'
require 'vagrant/hostmaster/test_helpers'

module Vagrant
  module Hostmaster
    class VMTest < Test::Unit::TestCase
      include Vagrant::TestHelpers
      include Vagrant::Hostmaster::TestHelpers

      def setup
        super

        # TODO: test both windows and non-windows
        Util::Platform.stubs(:windows?).returns(false)
        @hosts_file = Tempfile.new('hosts')
        hostmaster_box 'hostmaster.dev', '123.45.67.89', '01234567-89ab-cdef-fedc-ba9876543210'
        @vms = hostmaster_vms(vagrant_env(vagrantfile(hostmaster_config)))
      end

      def teardown
        @hosts_file.unlink
        clean_paths
        super
      end

      def test_hosts_path
        assert_equal '/etc/hosts', Vagrant::Hostmaster::VM.hosts_path
      end

      def test_hosts_path_for_windows
        Util::Platform.stubs(:windows?).returns(true)
        ENV.stubs(:[]).with('SYSTEMROOT').returns('/windows')
        assert_equal '/windows/system32/drivers/etc/hosts', Vagrant::Hostmaster::VM.hosts_path
      end

      def test_add_local_hosts_entry
        Vagrant::Hostmaster::VM.stubs(:hosts_path).returns @hosts_file.path
        @vms.each { |vm| vm.add }
        assert_local_host_entries_for @vms, @hosts_file
      end

      def test_list_local_hosts_entry
        Vagrant::Hostmaster::VM.stubs(:hosts_path).returns @hosts_file.path
        write_local_host_entries_for @vms, @hosts_file
        @vms.each { |vm| vm.list }
        assert false
      end

      def test_remove_local_hosts_entry
        Vagrant::Hostmaster::VM.stubs(:hosts_path).returns @hosts_file.path
        write_local_host_entries_for @vms, @hosts_file
        @vms.each { |vm| vm.remove }
        assert_no_local_host_entries_for @vms, @hosts_file
      end

      def test_update
        Vagrant::Hostmaster::VM.stubs(:hosts_path).returns @hosts_file.path
        write_local_host_entries_for @vms, @hosts_file, :addresses => %w(10.10.10.10), :names => %w(www.hostmaster.dev)
        @vms.each { |vm| vm.update }
        assert_local_host_entries_for @vms, @hosts_file
      end
    end
  end
end
