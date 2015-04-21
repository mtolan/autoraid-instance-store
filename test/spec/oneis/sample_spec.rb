require 'spec_helper'

describe "host oneis" do
  after(:all) do
    host = ENV['TARGET_HOST']
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
    it { should_not be_mounted.with( :device => '/dev/md0' ) }
  end
end