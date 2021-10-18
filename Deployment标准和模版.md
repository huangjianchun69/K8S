### Deployment yaml文件配置标准图
![image](https://github.com/huangjianchun69/K8S/blob/main/Deployment%E6%A0%87%E5%87%86%E5%92%8C%E6%A8%A1%E7%89%88/deployment.png)

### Deployment yaml文件配置模版
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-template
  namespace: portal
  labels:
    app: nginx-template
  annotations:            
    dedicated: "this is a template for mlink to create deployment"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  strategy:
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
    type: RollingUpdate
  progressDeadlineSeconds: 600
  minReadySeconds: 120
  revisionHistoryLimit: 10
  template:
    metadata:
      labels:
        app: nginx-template
    spec:
      containers:
      - name: nginx-template
        image: njreg.jpushoa.com/nginx:1.17.6
        imagePullPolicy: IfNotPresent
        imagePullSecrets:
        - name: regsecret
        lifecycle:
          preStop:
            exec:
              command: ["sleep", "5"]
        ports:
        - containerPort: 80
          name: service
          protocol: TCP
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        resources:
          requests:
            memory: "64Mi"
            cpu: "256m"
            ephemeral-storage: "2Gi"
          limits:
            memory: "128Mi"
            cpu: "512m"
            ephemeral-storage: "4Gi"
        livenessProbe:   
          tcpSocket:
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        volumeMounts:
        - mountPath: /var/log/nginx/access.log
          name: logs
        - mountPath: /var/log/nginx/error.log
          name: elklogs
        - mountPath: /etc/nginx/nginx.conf
          name: config
        - mountPath: /etc/nginx/nginx.crt
          name: nginx-cert
      dnsConfig:
        nameservers:
        - 10.96.0.10
        options:
        - name: ndots
          value: "2"  #ndots:2 表示有两个点的域名直接使用绝对域名进行解析，无法解析时才会添加K8S后缀，减少域名查询次数。
        - name: single-request-reopen
        searches:
        - portal.svc.cluster.local
        - svc.cluster.local
      dnsPolicy: None 
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: mlink
                operator: In
                values:
                - true
              - key: sms
                operator: NotIn
                values:
                - true
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            preference:
              matchExpressions:
              - key: mlink-a
                operator: In
                values:
                - true
              - key: mlink-mgnt
                operator: In
                values:
                - true
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: security
                operator: In
                values:
                - S1
            topologyKey: failure-domain.beta.kubernetes.io/zone
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: security
                  operator: In
                  values:
                  - S2
              topologyKey: failure-domain.beta.kubernetes.io/zone
      tolerations:
      - effect: NoSchedule
        key: dedicated
        operator: Equal
        value: portal
      - effect: "NoExecute"
        key: "security"
        operator: "Equal"
        value: "S3"
        tolerationSeconds: 3600
      restartPolicy: Always
      schedulerName: default-scheduler
      terminationGracePeriodSeconds: 60
      securityContext: {}
      volumes:
      - hostPath:
          path: /opt/developer/nginx
          type: Directory
        name: logs
      - emptyDir: {}
        name: elklogs
      - configMap:
          defaultMode: 420
          name: nginx-config
        name: config
      - secret:
          defaultMode: 420
          secretName: nginx-cert
        name: nginx-cert
```
