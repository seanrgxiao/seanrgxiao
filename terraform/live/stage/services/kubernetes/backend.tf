terraform {
  # backend "remote" {
  #   hostname     = "app.terraform.io" # 通常是这个，除非您有私有部署
  #   organization = "batangas" # 替换为您的组织名称
  #   workspaces {
  #     name = "stage_kubernetes" # 替换为您的工作空间名称
  #   }
  # }
  backend "local" {
    path = ".terraform.tfstate"
  }
}
