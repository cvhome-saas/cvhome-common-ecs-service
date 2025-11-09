# Define scaling target
resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.auto_scale ? 1 : 0
  max_capacity       = var.service.desired * 3
  min_capacity       = var.service.desired
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Target Tracking Policy - CPU Utilization
resource "aws_appautoscaling_policy" "ecs_target_tracking_cpu" {
  count              = var.auto_scale ? 1 : 0
  name               = "${var.project}-${var.service_name}-cpu-target-${var.env}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 60   # Maintain average CPU around 60%
    scale_in_cooldown  = 300  # seconds
    scale_out_cooldown = 60
  }
}

# Optionally: Add Memory-based Target Tracking (if needed)
resource "aws_appautoscaling_policy" "ecs_target_tracking_memory" {
  count              = var.auto_scale ? 1 : 0
  name               = "${var.project}-${var.service_name}-memory-target-${var.env}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 70   # Maintain average Memory around 70%
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
