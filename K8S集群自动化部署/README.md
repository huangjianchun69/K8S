### Kubernetes高可用集群
```
inventory.cfg
roles/cert/tasks/main.yaml
group_vars/all.yaml

#更改证书年限(876000h  100年)：
roles/cert/files/ca-config.json  
./roles/cert/files/etcd-ca-csr.json
./roles/cert/files/front-proxy-ca-csr.json

#部署k8s集群：
ansible-playbook -i inventory.cfg site.yaml -u huangjc -k -b -t cert,init,install_etcd,install_master,install_node

wget https://njreg.jpushoa.com/kubernetes/bin/kubernetes-1.18.2/kubectl
#拷贝配置文件，用于master执行kubectl命令
cp /etc/kubernetes/pki/k8s-lbs.jpushoa.com/admin.kubeconfig /root/.kube/config

# 清理k8s 集群
systemctl stop kube-apiserver kube-controller-manager kube-scheduler kube-proxy kubelet etcd docker && \
systemctl disable kube-apiserver kube-controller-manager kube-scheduler kube-proxy kubelet etcd docker && \
rm -rf /etc/kubernetes   /var/lib/kubelet  /var/lib/docker /var/lib/etcd
# 清理之后重启重启机器
reboot
```
Kubernetes是容器集群管理系统，本项目可以实现容器集群的自动化部署，自动添加节点等功能。

通过kubernetes你可以:

- 快速部署应用 
- 快速扩展应用
- 节省资源，优化硬件资源的使用


本工具使用ansible playbook初始化系统配置，安装kubernetes高可用集群，并可进行node节点添加等。

版本说明：

| 名称       | 版本                         |
| ---------- | ---------------------------- |
| kubernetes | 1.15.12 1.16.9 1.17.5 1.19.6 |
| docker     |           18.09.9            |
| system     |           CentOS 7           |

##使用方法：

###一 准备资源

1.1 准备机器资源，机器可使用数据盘存放数据，也可使用根磁盘存放数据。

1.2 请按照inventory.cfg格式填写以上准备资源

```
#本组内填写etcd服务器
[etcd]
x.x.x.x
......

#本组内填写elb服务器
[elb]
x.x.x.x
......

#本组内填写master服务器
[master]
x.x.x.x
......

#本组包含普通node, ingress-nginx和traefik节点，无需修改
[all_node:children]
node
ingress_nginx
traefik

#本组内填写node服务器
[node]
x.x.x.x
......

#本组内填写ingress-nginx服务器,如不打算安装ingress-nginx，可留空，无需填写。集群将不会安装ingress-nginx组件。
[ingress_nginx]
x.x.x.x
......

#本组内填写traefik服务器,如不打算安装traefik，可留空，无需填写。集群将不会安装traefik组件。
[traefik]
x.x.x.x
......

### 二 修改相关配置

编辑group_vars/all文件，填入相关参数
| 配置项                  |                                说 明                                             |
| ---------               | -------------------------------------------------------------------------------- |
| kernel_version          | 指定OS系统需升级的内核版本，无需修改                                             |
| docker_version          | 指定docker版本，无需修改                                                         |
| cni_network             | 指定安装到集群的cni网络插件，支持kube-router, flannel                            |
| cni_version             | 指定cni版本，/opt/cni/bin目录内的执行文件，无需修改                              |
| etcd_version            | 指定etcd版本，无需修改                                                           |
| kubernetes_version      | 指定kubernetes版本，支持1.15.12 1.16.9 1.17.5 1.18.2                             |
| apiserver_vip           | 指定apiserver VIP                                                                |
| apiserver_vip_mask      | 指定apiserver VIP的掩码                                                          |
| resolv                  | 指定容器使用dnsPolicy: Default时使用dns解释文件                                  |
| kubelet_bootstrap_token | bootstrap token，可使用head -c 16 /dev/urandom | od -An -t x | tr -d ' '命令生成 |
| pod_subnet              | 指定kubernetes集群容器的ip网段                                                   |
| pod_subnet_mask         | 指定kubernetes集群容器的ip网段的掩码                                             |
| node_subnet_mask        | 指定分配给每个节点的容器ip网段的掩码                                             |
| service_subnet          | 指定kubernetes集群service的ip网段                                                |
| service_subnet_mask     | 指定kubernetes集群service的ip网段的掩码                                          |
| repo_url                | 指定kernel,docker,kubernetes仓库url                                              |
| image_repo_url          | 指定镜像仓库地址                                                                 |
| ssl_dir                 | 指定节点中存放证书的目录                                                         |
- 注: 以下程序默认数据目录

- etcd数据目录: /var/lib/etcd
- docker数据目录: /var/lib/docker
- kubelet数据目录: /var/lib/kubelet

###三 使用方法

### 3.1 部署集群

1 数据盘初始化(可只初始化某些节点的数据盘，执行下面的命令时加上-l 参数，如 -l etcd)

```
ansible-playbook -i inventory.cfg init.yaml -u username -b -k
```

2 只签发节点证书和生成kubeconfig文件

```
ansible-playbook -i inventory.cfg site.yaml -u username -b -k -t cert
```

3 安装etcd

```
ansible-playbook -i inventory.cfg site.yaml -u username -b -k -t install_etcd
```

4 安装elb节点

```
ansible-playbook -i inventory.cfg site.yaml -u username -b -k -t install_elb
```

4 安装master节(如单独安装master节点，需确保etcd和elb已正常运行)

```
ansible-playbook -i inventory.cfg site.yaml -u username -b -k -t cert,init,install_master
```

5 安装及后续添加node节点(如单独安装node节点，需确保master已正常运行)

```
ansible-playbook -i inventory.cfg site.yaml -u username -b -k -t cert,init,install_node
```

6 安装及后续添加ingress-nginx节点及组件(如单独安装ingress-nginx节点及组件，需确保master已正常运行)

```
ansible-playbook -i inventory.cfg site.yaml -u username -b -k -t cert,init,install_node,install_ingress-nginx
```

7 安装及后续添加traefik节点及组件(如单独安装traefik节点及组件，需确保master已正常运行)

```
ansible-playbook -i inventory.cfg site.yaml -u username -b -k -t cert,init,install_node,install_traefik
```

8 全部安装

```
ansible-playbook -i inventory.cfg site.yaml -u username -b -k
```

