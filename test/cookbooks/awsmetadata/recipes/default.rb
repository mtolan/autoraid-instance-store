package 'python-virtualenv'
package 'python-pip'
package 'supervisor'

# apt-get update
# execute "loopback1" do
# 	command "ifconfig lo:1 169.254.169.254 netmask 255.255.255.0 up"
# end

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
    :device_list => node['awsmetadata']['device_list'],
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



# apt-get install -y python-virtualenv python-pip supervisor

# virtualenv /usr/local/mockaws
# mv /tmp/mockaws/* /usr/local/mockaws

# /usr/local/mockaws/bin/pip install -r /usr/local/mockaws/requirements.txt

# echo -e "[program:mockawsm]\ncommand=/usr/local/mockaws/bin/python /usr/local/mockaws/mockawsm.py" > /etc/supervisor/conf.d/mockaws.conf
# supervisorctl reload