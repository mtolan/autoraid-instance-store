require 'spec_helper'

describe "host twois" do
  after(:all) do
    host = ENV['TARGET_HOST']
    puts "vagrant destroy -f #{host}"
    `vagrant destroy -f #{host}`
  end

  describe package('mdadm') do
    it { should be_installed }
  end

  describe service('mdadm') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/mnt') do
    it { should be_directory }
    it { should be_mounted.with( :device => '/dev/md0' ) }
    it { should be_mounted.with( :type => 'ext3' ) }
  end
end