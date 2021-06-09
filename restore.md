## Backups

### Instance backups

Backups are configured to run with a cron job daily.

The output is a tarball name according to the DateTime of the backup. It ends up in the backups GitLab bucket (`gitlab-backups`)

### Kubernetes Secrets Backup

**Important!** Kubernetes secrets should be backed up manually using the following steps:

- `kubectl get secrets | grep rails-secret` (should be `gitlab-rails-secret`)
- `kubectl get secrets <rails-secret-name> -o jsonpath="{.data['secrets\.yml']}" | base64 --decode > secrets.yaml`
- secrets.yaml should be stored somewhere safe


## Restore

**Important!** To be able to restore an instance, it should be the same version as the one we took the backup from.

### Restore the Kubernetes secrets

- `kubectl get secrets | grep rails-secret` (should be `gitlab-rails-secret`)
- `kubectl delete secret <rails-secret-name>`
- `kubectl create secret generic <rails-secret-name> --from-file=secrets.yml=<local-yaml-filepath>`

### Restart the pods

- `kubectl delete pods -lapp=sidekiq,release=<helm release name>`
- `kubectl delete pods -lapp=webservice,release=<helm release name>`
- `kubectl delete pods -lapp=task-runner,release=<helm release name>`

### Restoring the backup file

**Important!** The file should be in the `gitlab-backups` bucket

- Make sure the GitLab instance is running and the task runner pod is running
  - `kubectl get pods -lrelease=RELEASE_NAME,app=task-runner`
- Make sure that the backup tarball is named in the `<timestamp>_<version>_gitlab_backup.tar` format
- Run the backup utility to restore the tarball
  - `kubectl exec <Task Runner pod name> -it -- backup-utility --restore -t <timestamp>_<version>`


### (Optional) Restore the runner registration token

After restoring, the included runner will not be able to register to the instance because it no longer has the correct registration token.

- Find the new shared runner token located on the `admin/runners` webpage of your GitLab installation
- Find the name of existing runner token Secret stored in Kubernetes
  - `kubectl get secrets | grep gitlab-runner-secret`
- Delete the existing secret
  - `kubectl delete secret <runner-secret-name>`
- Create the new secret with two keys, (runner-registration-token with your shared token, and an empty runner-token)
  - `kubectl create secret generic <runner-secret-name> --from-literal=runner-registration-token=<new-shared-runner-token> --from-literal=runner-token=""`
