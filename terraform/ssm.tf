locals {
  ssm_key_type = {
    "/db/password" = "SecureString"
    "/db/username" = "String"
  }

  ssm_values = {
    "/db/password" = "VeryStrongPassword"
    "/db/username" = "root"
  }

}

resource "aws_ssm_parameter" "this" {
  for_each = local.ssm_key_type

  name  = each.key
  type  = each.value
  value = local.ssm_values[each.key]

  lifecycle {
    ignore_changes = [value]
  }
}


