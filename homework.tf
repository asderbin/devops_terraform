terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.105.0"
    }
  }
}

provider "yandex" {
  token     = "asderbin_token_yandex"  
  cloud_id  = "b1gflqftlca9jatlviqa" 
  folder_id = "b1ggssofjksgcf4d46cl" 
  zone = "ru-central1-a"             
}

resource "yandex_compute_instance" "build" {
  name = "build"
  allow_stopping_for_update = true
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    disk_id = yandex_compute_disk.build_ubuntu2004_15GB.id
  }
  network_interface {
    subnet_id = "e9b5gvivpqjj7upb4c9l"  
    nat       = true
  }
  metadata = {
    user-data = "${file("./key.yml")}" 
  }
  scheduling_policy {
    preemptible = true  
  }
  connection {
    type        = "ssh"
    user        = "asderbin"                            
    private_key = file("/root/.ssh/id_rsa")           
    host        = yandex_compute_instance.build.network_interface.0.nat_ip_address  
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update", 
      "sudo apt install openjdk-11-jdk maven docker.io mc git -y",  
      "cd /home/asderbin ",
      "git clone https://github.com/Stupin87/boxfuse1.git",                
      "cd /home/asderbin/boxfuse1 && mvn package",
      "cp ./Dockerfile /home/asderbin/boxfuse1/target/Dockerfile",
      "cd /home/asderbin/boxfuse1/target/hello-1.0.war ",      
            
      "sudo docker build -t boxfuse1 .",
      "sudo docker tag boxfuse1 cr.yandex/${yandex_container_registry.my-reg.id}/boxfuse1",
      "sudo docker push cr.yandex/${yandex_container_registry.my-reg.id}/boxfuse1"     
         ]
  }
}

resource "yandex_compute_instance" "prod" {
  name = "prod"  
  allow_stopping_for_update = true
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    disk_id = yandex_compute_disk.prod_ubuntu2004_15GB.id
  }
  network_interface {
    subnet_id = "e9b5gvivpqjj7upb4c9l"  
    nat       = true
  }
  metadata = {
    user-data = "${file("./key.yml")}"  
  }
  scheduling_policy {
    preemptible = true  
  }
  connection {
    type        = "ssh"
    user        = "asderbin"                             
    private_key = file("/root/.ssh/id_rsa")           
    host        = yandex_compute_instance.prod.network_interface.0.nat_ip_address  
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update", 
      "sudo apt install  mc docker.io -y",
      "sudo docker pull cr.yandex/${yandex_container_registry.my-reg.id}/boxfuse1",
      "sudo docker run -d -p 8080:8080 cr.yandex/${yandex_container_registry.my-reg.id}/boxfuse1"   
      
    ]
  }
    depends_on = [
    yandex_compute_instance.build
  ]
}

data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2004-lts"
}

resource "yandex_compute_disk" "build_ubuntu2004_15GB" {
  type     = "network-ssd"
  zone     = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_image.id
  size     = 15
}
 
 resource "yandex_compute_disk" "prod_ubuntu2004_15GB" {
  type     = "network-ssd"
  zone     = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_image.id
  size = 15
 }
resource "yandex_container_registry" "my-reg" {
  name = "docker"
  folder_id = "b1g7eg0ncndrirrrbobi"
  labels = {
    my-label = "it-is-boxfuse1"
  }
}
resource "yandex_container_registry_iam_binding" "puller" {
  registry_id = yandex_container_registry.my-reg.id
  role        = "container-registry.images.puller"
  members = [
    "system:allUsers",
  ]
}
resource "yandex_container_registry_iam_binding" "pusher" {
  registry_id = yandex_container_registry.my-reg.id
  role        = "container-registry.images.pusher"
  members = [
    "system:allUsers",
  ]
}