# docker-backup-kubernetes ![https://hub.docker.com/r/steffenmllr/docker-backup-kubernetes](https://img.shields.io/docker/pulls/steffenmllr/docker-backup-kubernetes.svg)

> Uses the [ruby backup](https://github.com/backup/backup) in kubernetes as a cron job.  


### Sample

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: backup-config
  namespace: "my-namespace"
data:
  backup.rb: |
    # encoding: utf-8
    Model.new(:backup, 'Backup databases to s3') do
      ##
      # Backup PostgreSQL
      #
      database PostgreSQL, :de do |db|
        db.username           = ENV['POSTGRES_USER'].dup
        db.password           = ENV['POSTGRES_PASSWORD'].dup
        db.host               = "postgres-service"
      end
      store_with S3 do |s3|
        # AWS Credentials
        s3.access_key_id     = ENV['AWS_ACCESS_KEY_ID'].dup
        s3.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'].dup
        s3.region             = 'eu-central-1'
        s3.bucket             = 'my-backup'
        s3.path               = '/s3-path'
      end
      encrypt_with OpenSSL do |encryption|
        encryption.password = ENV['DATABASE_ENCR_PASSWORD'].dup
        encryption.base64   = true
        encryption.salt     = true
      end
      compress_with Gzip
      ##
      # Notify
      #
      notify_by Slack do |slack|
        slack.on_success           = true
        slack.on_warning           = true
        slack.on_failure           = true
        slack.webhook_url = 'URL
      end
    end
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: database-backup
  namespace: "my-namespace"
spec:
  schedule: "0 2 * * *"
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
              env:
                - name: POSTGRES_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: app-secrets
                      key: POSTGRES_PASSWORD

                - name: POSTGRES_USER
                  valueFrom:
                    secretKeyRef:
                      name: app-secrets
                      key: POSTGRES_USER

                - name: DATABASE_ENCR_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: app-secrets
                      key: DATABASE_ENCR_PASSWORD

                - name: AWS_ACCESS_KEY_ID
                  valueFrom:
                    secretKeyRef:
                      name: app-secrets
                      key: AWS_ACCESS_KEY_ID

                - name: AWS_SECRET_ACCESS_KEY
                  valueFrom:
                    secretKeyRef:
                      name: app-secrets
                      key: AWS_SECRET_ACCESS_KEY

              command:
                - "/bin/sh"
                - "-c"
                - |
                  backup generate:model --trigger backup --databases="postgresql"
                  cp /tmp/models/backup.rb /root/Backup/models/backup.rb
                  backup perform --trigger backup
```
