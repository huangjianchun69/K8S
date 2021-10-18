![image](https://github.com/huangjianchun69/K8S/blob/main/Service.png)
### service yaml文件配置模版
```
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: default
  labels:
    app: web
  annotations:
    dedicated: "this is a template for mlink to create service"
spec:
  ports:
  - name: serve
    port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 32768
  selector:
    app: web
  sessionAffinity: None
  type: ClusterIP | NodePort | ExternalName
  externalName: my.database.example.com
```
