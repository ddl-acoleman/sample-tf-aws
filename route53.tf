data "aws_route53_zone" "zone" {
  name         = "${var.root_domain}."
  private_zone = false
}

resource "aws_route53_record" "domain" {
  name    = local.domain
  type    = "CNAME"
  zone_id = data.aws_route53_zone.zone.id
  records = [aws_lb.this.dns_name]
  ttl     = 60
}

resource "aws_route53_record" "wildcard_domain" {
  name    = "*.${local.domain}"
  type    = "CNAME"
  zone_id = data.aws_route53_zone.zone.id
  records = [local.domain]
  ttl     = 60
}
