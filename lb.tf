resource "aws_lb_target_group" "this" {
  name     = lower("${var.identifiant}-TG")
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-499"
  }
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.vm.id
  port             = 80
}

resource "aws_security_group_rule" "lb_from_internet" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.lb.id
}

resource "aws_security_group_rule" "internet_to_lb" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = data.aws_security_group.lb.id
  cidr_blocks       = [data.aws_subnet.public-a.cidr_block, data.aws_subnet.public-b.cidr_block]
}

resource "aws_lb_listener" "this" {
 load_balancer_arn = data.aws_lb.lb.arn
 port              = "8080"
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.this.arn
 }
}

resource "aws_security_group_rule" "ec2_from_lb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.lb.id
  security_group_id        = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "lb_to_ec2" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = data.aws_security_group.lb.id
  cidr_blocks       = [data.aws_subnet.private-a.cidr_block, data.aws_subnet.private-b.cidr_block]
}
