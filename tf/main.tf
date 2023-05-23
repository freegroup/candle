locals {
  string_liste = join(", ", var.meine_string_liste)
}

output "joined" {
  description = "Die gesamte Liste als einzelner String"
  value       = local.string_liste
}
output "raw" {
  description = "Die gesamte Liste als einzelner String"
  value       = var.meine_string_liste
}
