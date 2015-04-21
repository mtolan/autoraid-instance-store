package 'python-virtualenv'
package 'python-pip'
package 'supervisor'

execute "create virtualenv" do
	command "virtualenv /usr/local/mockaws"
	not_if { File.exists?('/usr/local/mockaws') }
end

cookbook_file "requirements.txt" do
  path "/usr/local/mockaws/requirements.txt"
  action :create_if_missing
end

execute "install requirements" do
	command "/usr/local/mockaws/bin/pip install -r /usr/local/mockaws/requirements.txt"
end

template "/usr/local/mockaws/mockawsm.py" do
  source "mockawsm.py.erb"
  action :create_if_missing
  variables({
    :block_device_json => node['awsmetadata']['block_device_json']
  })
end

service "supervisor" do
	action [:enable, :start]
end

cookbook_file "mockaws.conf" do
  path "/etc/supervisor/conf.d/mockaws.conf"
  action :create_if_missing
  notifies :restart, "service[supervisor]"
end
