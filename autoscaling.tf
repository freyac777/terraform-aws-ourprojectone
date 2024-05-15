
resource "aws_launch_template" "projecttemplate" {
  name_prefix   = "projecttemplate-launch-template"
  image_id      = "ami-07caf09b362be10b8" 
  instance_type = "t2.large"   
  key_name      = "local"   
  count = 1
  network_interfaces {
  security_groups = [aws_security_group.projectsec.id, aws_security_group.projectsec1.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[count.index].id
  delete_on_termination       = true 
}



#   user_data = base64encode (<<EOF
# #!/bin/bash
# yum update -y
# yum install -y httpd php php-mysqlnd
# systemctl start httpd
# systemctl enable httpd
# wget -c https://wordpress.org/latest.tar.gz
# tar -xvzf latest.tar.gz -C /var/www/html
# cp -r /var/www/html/wordpress/* /var/www/html/
# chown -R apache:apache /var/www/html/

# cd /var/www/html/
# echo "
# <?php
# define( 'DB_NAME', 'admin' );
# define( 'DB_USER', 'admin' );
# define( 'DB_PASSWORD', 'password' );
# define( 'DB_HOST', 'terraform-**************************.ct6kq4048kie.us-east-1.rds.amazonaws.com' );
# define( 'DB_CHARSET', 'utf8mb4' );
# define( 'DB_COLLATE', '' );
# define( 'AUTH_KEY',         'admin' );                                                             
# define( 'SECURE_AUTH_SALT', 'admin' );
# define( 'LOGGED_IN_SALT',   'admin' );
# define( 'NONCE_SALT',       'admin' );
# \$table_prefix = 'wp_';
# define( 'WP_DEBUG', false );
# if ( ! defined( 'ABSPATH' ) ) {
#         define( 'ABSPATH', __DIR__ . '/' );
# }
# require_once ABSPATH . 'wp-settings.php';
# " > wp-config.php

# service httpd restart
# EOF
#   )
    
#}

user_data     = base64encode (<<-EOF
                  #!/bin/bash
                  yum update -y
                  yum install -y httpd php php-mysqlnd
                  systemctl start httpd
                  systemctl enable httpd
                  wget -c https://wordpress.org/latest.tar.gz
                  tar -xvzf latest.tar.gz -C /var/www/html
                  cp -r /var/www/html/wordpress/* /var/www/html/
                  chown -R apache:apache /var/www/html/
                  mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
                  sed -i "s/database_name_here/admin/" /var/www/html/wp-config.php
                  sed -i "s/username_here/admin/" /var/www/html/wp-config.php
                  sed -i "s/password_here/password/" /var/www/html/wp-config.php
                  sed -i "s/localhost/${aws_db_instance.writer.endpoint}/" /var/www/html/wp-config.php
                  EOF
                  )
}

 
# Create auto scaling



resource "aws_autoscaling_group" "asg" {
  name = "projecttemplate-asg"

  launch_template {
    id = aws_launch_template.projecttemplate[0].id
    # vesrion = "$Latest"
  }

  min_size             = 1
  max_size             = 10
  desired_capacity     = 3 
  health_check_type    = "EC2"
  health_check_grace_period = 300  
  vpc_zone_identifier = [aws_subnet.public[0].id, aws_subnet.public[1].id, aws_subnet.public[2].id,]
}

# # Create an ALB


resource "aws_lb" "wordpress_alb" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.projectsec1.id]       # needt to change
  #subnets            = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
  subnets            = concat(aws_subnet.public[*].id)
  tags = {
    Name = "WordPressALB"
  }
}



resource "aws_lb_listener" "wordpress" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Wordpress_TG.arn
  }
}


resource "aws_lb_target_group" "Wordpress_TG" {
   name     = "learn-asg-terramino"
   port     = 80
   protocol = "HTTP"
   vpc_id   = aws_vpc.main.id
 }

resource "aws_autoscaling_attachment" "wordpress_AAA" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn  = aws_lb_target_group.Wordpress_TG.arn
  
}