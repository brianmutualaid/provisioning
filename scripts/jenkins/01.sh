pushd /etc/yum.repos.d/
curl -O https://pkg.jenkins.io/redhat/jenkins.repo
curl -O http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo
popd
rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
rpm --import https://www.virtualbox.org/download/oracle_vbox.asc
yum -y install git
yum -y install java-1.8.0-openjdk
yum -y install jenkins
rpm -ivh https://releases.hashicorp.com/vagrant/1.9.5/vagrant_1.9.5_x86_64.rpm
systemctl enable jenkins
systemctl start jenkins

