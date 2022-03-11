1、yaml 文件：
```
# ldap.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ldap-deployment
spec:
  selector:
    matchLabels:
      app: ldap
  replicas: 3
  template:
    metadata:
      labels:
        app: ldap
    spec:
      containers:
      - name: ldap
        image: njreg.jpushoa.com/sa/openldap-server:20200916
        ports:
        - containerPort: 636
        securityContext:
          privileged: true  #特权模式
        volumeMounts:
          - name: localtime
            mountPath: /etc/localtime  #挂载卷（目的）
      volumes:
        - name: localtime
          hostPath:
            path: /etc/localtime  #定义卷（源）

---

apiVersion: v1
kind: Service
metadata:
  name: ladp-service
spec:
  selector:
    app: ldap
  ports:
  - protocol: TCP
    port: 636
    targetPort: 636

# 启动容器
kubectl apply -f ldap.yaml
```

2、对外服务 ingress + tcp 转发：
```
# tcp-internal-services.yaml
# tcp-internal-services 在 ingress 启动时要引用好
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-internal-services
  namespace: ingress-nginx
data:
  '636': default/ladp-service:636
```

3、添加域名解析为ingress 节点ip即可使用
