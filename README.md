# docker-backup-kubernetes ![https://hub.docker.com/r/steffenmllr/docker-backup-kubernetes](https://img.shields.io/docker/pulls/steffenmllr/docker-backup-kubernetes.svg)

> Uses the [ruby backup](https://github.com/backup/backup) in kubernetes as a cron job.  


### Sample

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backup-config
  namespace: "my-namespace"
data:

  backup.rb: |
    Model.new(:backup, 'my-backup') do
      ##
      # PostgreSQL [Database]
      #
      database PostgreSQL do |db|
        db.name               = ENV['DATABASE_NAME']
        db.username           = ENV['DATABASE_USER']
        db.password           = ENV['DATABASE_PASSWORD']
        db.host               = ENV['DATABASE_SERVER']
        db.port               = ENV['DATABASE_PORT']
      end
      ##
      # Amazon Simple Storage Service [Storage]
      #
      store_with S3 do |s3|
        s3.access_key_id     = ENV['AWS_ACCESS_KEY_ID']
        s3.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
        s3.region            = ENV['AWS_REGION']
        s3.bucket            = ENV['AWS_BUCKET']
        s3.path              = "databases"
        s3.keep              = 120
      end
    end


---

apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: backup-secrets
  namespace: "my-namespace"
stringData:
  DATABASE_NAME: "DATABASE_NAME"
  DATABASE_USER: "DATABASE_USER"
  DATABASE_PASSWORD: "DATABASE_PASSWORD"
  DATABASE_SERVER: "DATABASE_SERVER"
  DATABASE_PORT: "DATABASE_PORT"  
  AWS_ACCESS_KEY_ID: "AWS_ACCESS_KEY_ID"
  AWS_SECRET_ACCESS_KEY: "AWS_SECRET_ACCESS_KEY"
  AWS_REGION: "AWS_REGION"
  AWS_BUCKET: "AWS_BUCKET"

---

apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: database-backup
  namespace: "my-namespace"
spec:
  schedule: "0 0 * * *" # https://crontab.guru/every-midnight
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      backoffLimit: 4
      template:
        spec:
          terminationGracePeriodSeconds: 0
          restartPolicy: Never
          volumes:
            - name: backup-config
              configMap:
                name: backup-config
          containers:
            - name: backup
              image: steffenmllr/docker-backup-kubernetes:v4.4.1
              imagePullPolicy: Always
              volumeMounts:
                - name: backup-config
                  mountPath: /tmp/models
              envFrom:
                - secretRef:
                    name: backup-secrets

              command:
                - "/bin/sh"
                - "-c"
                - |
                  backup generate:model --trigger backup --databases="postgresql"
                  cp /tmp/models/backup.rb /root/Backup/models/backup.rb
                  backup perform --trigger backup
```
