resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.auto_scale ? 1 : 0
  max_capacity       = var.service.desired * 3
  min_capacity       = var.service.desired
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale Out Policy (Increase capacity)
resource "aws_appautoscaling_policy" "ecs_scale_out" {
  count              = var.auto_scale ? 1 : 0
  name               = "${var.project}-${var.service_name}-scale-out-${var.env}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

# Scale In Policy (Decrease capacity)
resource "aws_appautoscaling_policy" "ecs_scale_in" {
  count              = var.auto_scale ? 1 : 0
  name               = "${var.project}-${var.service_name}-scale-in-${var.env}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# CloudWatch Alarm - High CPU
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.auto_scale ? 1 : 0
  alarm_name          = "${var.project}-${var.service_name}-cpu-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  datapoints_to_alarm = 2

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.this.name
  }

  alarm_description = "Triggers when CPU exceeds 70%"
  alarm_actions     = [aws_appautoscaling_policy.ecs_scale_out[0].arn]

  tags = var.tags
}

# CloudWatch Alarm - Low CPU
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count               = var.auto_scale ? 1 : 0
  alarm_name          = "${var.project}-${var.service_name}-cpu-low-${var.env}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  datapoints_to_alarm = 3

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.this.name
  }

  alarm_description = "Triggers when CPU falls below 30%"
  alarm_actions     = [aws_appautoscaling_policy.ecs_scale_in[0].arn]

  tags = var.tags
}

# CloudWatch Alarm - High Memory
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count               = var.auto_scale ? 1 : 0
  alarm_name          = "${var.project}-${var.service_name}-memory-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  datapoints_to_alarm = 2

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.this.name
  }

  alarm_description = "Triggers when Memory exceeds 70%"
  alarm_actions     = [aws_appautoscaling_policy.ecs_scale_out[0].arn]

  tags = var.tags
}

# CloudWatch Alarm - Low Memory
resource "aws_cloudwatch_metric_alarm" "memory_low" {
  count               = var.auto_scale ? 1 : 0
  alarm_name          = "${var.project}-${var.service_name}-memory-low-${var.env}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  datapoints_to_alarm = 3

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.this.name
  }

  alarm_description = "Triggers when Memory falls below 30%"
  alarm_actions     = [aws_appautoscaling_policy.ecs_scale_in[0].arn]

  tags = var.tags
}