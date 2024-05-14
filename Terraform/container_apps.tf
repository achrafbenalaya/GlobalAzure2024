resource "azurerm_container_app_environment" "env" {
  name                       = "aca-environment"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
}

resource "azurerm_container_app" "app-helloworld" {
  name                         = "containerapps-helloworld"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 3
    container {
      name   = "helloworld-app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "app-nginx" {
  name                         = "containerapps-nginx"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 3
    container {
      name   = "nginx-app"
      image  = "nginx:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "app-counter" {
  name                         = "containerapps-counter"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 3
    container {
      name    = "counter-app"
      image   = "busybox:latest"
      cpu     = 0.25
      memory  = "0.5Gi"
      command = ["/bin/sh", "-c", "i=0; while true; do echo 'This is demo log $i: $(date)'; i=$((i+1)); sleep 10; done"]
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}


resource "azurerm_container_app_environment_storage" "aca_env_storage" {
  name                         = "containerapp-storage"
  container_app_environment_id = azurerm_container_app_environment.env.id
  account_name                 = azurerm_storage_account.storage.name
  share_name                   = azurerm_storage_share.file_share.name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  access_mode                  = "ReadWrite" # "ReadOnly"
}


resource "azurerm_container_app" "aca_app" {
  name                         = "aca-demostorage-app"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "containerapp"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      volume_mounts {
        name = "containerapp-storage"
        path = "/mnt/app-azure-file"
      }
    }

    volume {
      name         = "containerapp-storage"
      storage_name = azurerm_container_app_environment_storage.aca_env_storage.name
      storage_type = "AzureFile" # "EmptyDir"
    }
  }
}




//with user asign identity

resource "azurerm_container_app" "aca_identityapp" {
  name                         = "aca-identityapp-demo001"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "aca-identityapp-demo001"
      image  = "ghcr.io/jelledruyts/inspectorgadget:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "MY_ENV_VAR"
        value = "Hello Container Apps!"
      }
      env {
        name        = "MY_SECRET_001"
        secret_name = "my-secret-001"
      }
    }
  }

  secret {
    name  = "my-secret-001"
    value = "https://kvacaglobalazure.vault.azure.net/secrets/my-secret-001/6cf7849cb9ac4134a1e5cf352b47d2ef"
    # expect secret_ref to be added to azurerm provider
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity_aca.id]
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  lifecycle {
    ignore_changes = [secret]
  }
}

output "app_url" {
  value = azurerm_container_app.aca_identityapp.latest_revision_fqdn
}

resource "terraform_data" "add_secrets" {
  count            = 1
  triggers_replace = []

  lifecycle {
    replace_triggered_by = [azurerm_container_app.aca_identityapp]
  }

  provisioner "local-exec" {

    # interpreter = [ "bash", "-c" ]
    interpreter = ["PowerShell", "-Command"]

    command = <<-EOT
    
        az containerapp secret set `
          --name ${azurerm_container_app.aca_identityapp.name} `
          --resource-group ${azurerm_resource_group.rg.name} `
          --secrets my-secret-002=keyvaultref:${azurerm_key_vault_secret.secret_002.versionless_id},identityref:${azurerm_user_assigned_identity.identity_aca.id}

          az containerapp update `
          --name ${azurerm_container_app.aca_identityapp.name} `
          --resource-group ${azurerm_resource_group.rg.name} `
          --set-env-vars "MY_SECRET_002=secretref:my-secret-002"
         
      EOT
    when    = create
  }

  depends_on = [azurerm_container_app.aca_identityapp]
}