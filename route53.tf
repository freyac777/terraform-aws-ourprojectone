resource "aws_route53_record" "test" {
  zone_id = "Z06850201MTDYOMWHQFZZ"  # Specify the Route 53 hosted zone ID where you want to create the record
  name    = "www"  # Specify the domain name you want to associate with the ALB
  type    = "A"
  alias {
    name                   = aws_lb.wordpress_alb.dns_name  # Specify the DNS name of your ALB
    zone_id                = aws_lb.wordpress_alb.zone_id  # Specify the hosted zone ID of your ALB
    evaluate_target_health = true
  }
}

