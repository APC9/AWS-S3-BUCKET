locals {
  owners     = var.owners
  enviroment = var.enviroment
  name       = "${local.owners}-${local.enviroment}"

  tags = {
    owners     = local.owners
    enviroment = local.enviroment
  }
}

locals {
  files = [
    {
      key    = "imagen2.png"
      source = "./files/imagen2.png"
    },
    {
      key    = "img1.png"
      source = "./files/img1.png"
    },
    {
      key    = "prueba.txt"
      source = "./files/prueba.txt"
    }
  ]
}