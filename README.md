# https://cloud.yandex.ru/ru/docs/tracker/concepts/access
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
yc init (https://cloud.yandex.ru/ru/docs/cli/quickstart#linux_1)
yc config list

# prepare infrastructure
apt update
apt install mc -y
apt install git -y
apt install unzip -y 

# install terraform to /home/users/
git clone https://github.com/spring108/terraform.git
cd /tmp/terraform
unzip terraform_1.7.0_linux_amd64.zip
cp ./terraform /bin
terraform --version
configure terraform: setup providers-mirror from yandex
nano ~/.terraformrc - сыллка на документацию яндекс облака (https://cloud.yandex.ru/ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials)

# launch project 
cd /home/users/
git clone https://github.com/spring108/terraform_yandex.git
# terraform  config.tf -> token 
terraform init
terraform plan
terraform apply