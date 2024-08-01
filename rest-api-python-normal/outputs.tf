output "ecs_cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.flask_api.arn
}

output "ecs_service_id" {
  value = aws_ecs_service.flask_api.id
}
