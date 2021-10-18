# 本篇文章将学习如何使用 Pod，Deployment 与 Service 开始部署第一个应用

### 简单的解释：
```
1、Pod：用于运行容器，部署服务。
2、Deployment：管理pod，扩容、升级、回滚等
3、Service：发布Pod，为k8s 集群内提供负载均衡器。
4、ingress：对外发布service，为k8s 集群外提供负载均衡器。
```

### Pod
pod 是 kubernetes 中最小的编排单位，通常由一个容器组成 (有时候会有多个容器组成)。  
以下是一个 pod 资源配置文件的最小示例。  
我们使用 nginx:alpine 作为镜像部署了一个 Pod，并且暴露了 80 端口：
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  # 指定 label，便于检索
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    # 指定镜像
    image: nginx:alpine
    # 指定暴露端口
    ports:
    - containerPort: 80
```
使用 kubectly apply，部署 Pod
```
$ kubectl apply -f nginx.yaml
pod/nginx created
```
校验部署状态，此时 STATUS 为 Running 表明部署成功
```
# 获取 Pod 部署的状态，特别是 IP
# -o wide 列出IP/Node等更多信息
$ kubectl get pods nginx -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          14m   10.244.1.9   shuifeng   <none>           <none>
```

### Deployment
在 k8s 中编排应用可以更好地做弹性扩容，负载均衡。既然要均衡，一个 Pod 肯定不能均衡，自然要部署多个 Pod。  
docker-compose 可以简单地通过 docker-compose scale 来扩容，k8s 更不在话下了。  
在k8s中管理 Pod 的称作 Controller，我们可以使用 Deployment 这种 Controller 来为 Pod 进行扩容，当然它还可以滚动升级，回滚，金丝雀等等关于部署的事情。  
我们编写一个 Deployment 的资源配置文件：
```
spec.template: 指定要部署的 Pod
spec.replicas: 指定要部署的个数
spec.selector: 定位需要管理的 Pod
```
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    #指定管理哪个label
    matchLabels:
      app: nginx
  # 控制nginx 副本数
  replicas: 3
  # 定义pod 属性
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
# pod name 会自动生成：Deployment name + 字符串
```
我们使用 kubectl apply 部署生效后查看 Pod 以及 Deployment 状态
```
$ kubectl apply -f nginx.yaml

# nginx-deployment 部署的三个 pod 全部成功
$ kubectl get pods -o wide -l 'app=nginx'
NAME                                READY   STATUS    RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
nginx                               1/1     Running   1          4h29m   10.244.1.9    shuifeng   <none>           <none>
nginx-deployment-54f57cf6bf-57g8l   1/1     Running   0          23m     10.244.1.10   shuifeng   <none>           <none>
nginx-deployment-54f57cf6bf-ltdf7   1/1     Running   0          23m     10.244.1.11   shuifeng   <none>           <none>
nginx-deployment-54f57cf6bf-n8ppt   1/1     Running   0          23m     10.244.1.12   shuifeng   <none>           <none>

# READY 3/3 表明全部部署成功
$ kubectl get deploy nginx-deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           23m
```

### Service
现在我们已经部署了一个 Deployment，其中有三个 Pod，就有三个 IP，那我们如何向这三个 Pod 请求服务呢，何况每当上线部署后，就会产生新的 Pod IP。即我们如何做服务发现。  
我们可以通过 Service 解决这个问题，做指定 Deployment 或者特定集合 Pod 的网络层抽象。  
配置文件如下：
```
spec.selector: 指定如何选择 Pod
spec.ports: 指定如何暴露端口
```
```
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```
我们使用 kubectl apply 部署生效后查看 Service 状态
```
$ kubectl get svc nginx-service -o wide
NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE   SELECTOR
nginx-service   ClusterIP   10.108.9.49   <none>        80/TCP    11m   app=nginx
```

### 小结
通过配置 Deployment 与 Service ，此时我们可以在集群中通过服务发现访问域名。  
完整的配置文件如下:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```
