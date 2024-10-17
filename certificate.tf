provider "aws" {
    alias = "default"
    region = "us-east-1" # ACM certificates for CloudFront must be in us-east-1
}

resource "aws_acm_certificate" "wildcard_cert" {
  domain_name               = "*.agricco.io"
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# Fetch the hosted zone ID for agricco.io
data "aws_route53_zone" "agricco" {
  name         = "agricco.io"
  private_zone = false
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.agricco.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "wildcard_cert_validation" {
  certificate_arn         = aws_acm_certificate.wildcard_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  depends_on = [aws_route53_record.cert_validation]
}
