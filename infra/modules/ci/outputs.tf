output "role_arn" {
  description = "Set as GitHub secret AWS_ROLE_ARN."
  value       = aws_iam_role.github_ci.arn
}
