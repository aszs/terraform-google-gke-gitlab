# Values for gitlab/gitlab chart on GKE
global:
  edition: ce
  hosts:
    domain: ${DOMAIN}
    https: true
    gitlab: {}
    externalIP: ${INGRESS_IP}
    ssh: ~

  communityImages:
    # Default repositories used to pull Gitlab Community Edition images.
    # See the image.repository and workhorse.repository template helpers.
    migrations:
      repository: registry.gitlab.com/aszs/cng/gitlab-task-runner-ce
    sidekiq:
      repository: registry.gitlab.com/aszs/cng/gitlab-sidekiq-ce
    task-runner:
      repository: registry.gitlab.com/aszs/cng/gitlab-task-runner-ce
    webservice:
      repository: registry.gitlab.com/aszs/cng/gitlab-webservice-ce
    workhorse:
      repository: registry.gitlab.com/aszs/cng/gitlab-workhorse-ce

  ## doc/charts/globals.md#configure-ingress-settings
  ingress:
    configureCertmanager: true
    enabled: true
    tls:
      enabled: true
    annotations:
      external-dns.alpha.kubernetes.io/ttl: 10
      external-dns.alpha.kubernetes.io/hostname: ${DOMAIN}.


  ## doc/charts/globals.md#configure-postgresql-settings
  psql:
    password:
      secret: gitlab-pg
      key: password
    host: ${DB_PRIVATE_IP}
    port: 5432
    username: gitlab
    database: gitlabhq_production

  redis:
    password:
      enabled: false
    host: ${REDIS_PRIVATE_IP}

  ## doc/charts/globals.md#configure-minio-settings
  minio:
    enabled: false

  ## doc/charts/globals.md#configure-appconfig-settings
  ## Rails based portions of this chart share many settings
  appConfig:
    ## doc/charts/globals.md#general-application-settings
    enableUsagePing: false

    ## doc/charts/globals.md#lfs-artifacts-uploads-packages
    backups:
      bucket: ${PROJECT_ID}-gitlab-backups
    lfs:
      bucket: ${PROJECT_ID}-git-lfs
      connection:
        secret: gitlab-rails-storage
        key: connection
    artifacts:
      bucket: ${PROJECT_ID}-gitlab-artifacts
      connection:
        secret: gitlab-rails-storage
        key: connection
    uploads:
      bucket: ${PROJECT_ID}-gitlab-uploads
      connection:
        secret: gitlab-rails-storage
        key: connection
    packages:
      bucket: ${PROJECT_ID}-gitlab-packages
      connection:
        secret: gitlab-rails-storage
        key: connection

    ## doc/charts/globals.md#pseudonymizer-settings
    pseudonymizer:
      bucket: ${PROJECT_ID}-gitlab-pseudo
      connection:
        secret: gitlab-rails-storage
        key: connection

    omniauth:
      enabled: true
      autoSignInWithProvider:
      syncProfileFromProvider: ['google_oauth2']
      syncProfileAttributes: ['name', 'email', 'location']
      allowSingleSignOn: true
      blockAutoCreatedUsers: true
      autoLinkLdapUser: false
      autoLinkSamlUser: false
      autoLinkUser: ['saml']
      externalProviders: [] # we'll want to set this when we open up to the public
      allowBypassTwoFactor: []
      providers:
       - secret: gitlab-google-oauth2
         key: provider

  email:
    display_name: OneCommons
    from:     noreply@onecommons.org
    reply_to: noreply@onecommons.org

  smtp:
    enabled: true
    address: "smtp.sendgrid.net"
    port: 587
    user_name: "apikey"
    password:
      secret: "sendgrid-key"
      key: sendgrid-key
    domain: "smtp.sendgrid.net"
    authentication: "plain"
    starttls_auto: true
    tls: false


certmanager-issuer:
  email: ${CERT_MANAGER_EMAIL}

prometheus:
  install: false

redis:
  install: false

gitlab:
  gitaly:
    persistence:
      size: 200Gi
      storageClass: "pd-ssd"
  task-runner:
    backups:
      objectStorage:
        backend: gcs
        config:
          secret: google-application-credentials
          key: gcs-application-credentials-file
          gcpProject: ${PROJECT_ID}
      enabled: true
      schedule: "0 0 * *"
  # oc
    image:
      tag: ${TAG}
  migrations:
    image:
      tag: ${TAG}
  sidekiq:
    image:
      tag: ${TAG}
  webservice:
    image:
      tag: ${TAG}
    workhorse:
      tag: ${TAG}

postgresql:
  install: false

gitlab-runner:
  install: ${GITLAB_RUNNER_INSTALL}
  rbac:
    create: true
  runners:
    privileged: true
    locked: false
    cache:
      cacheType: gcs
      gcsBucketName: ${PROJECT_ID}-runner-cache
      secretName: google-application-credentials
      cacheShared: true

registry:
  enabled: true
  storage:
    secret: gitlab-registry-storage
    key: storage
    extraKey: gcs.json
