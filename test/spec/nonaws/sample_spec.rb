require 'spec_helper'

describe "host nonaws" do
  after(:all) do
    host = ENV['TARGET_HOST']
    `vagrant destroy -f #{host}`
  end

  describe package('mdadm') do
    it { should_not be_installed }
  end

  describe file('/mnt') do
    it { should be_directory }
    it { should_not be_mounted.with( :device => '/dev/md0' ) }
  end
end