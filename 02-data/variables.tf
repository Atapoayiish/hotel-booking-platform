variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_username" {
  type    = string
  default = "hoteladmin"
}
variable "db_name" {
  type    = string
  default = "hoteldb"
}
