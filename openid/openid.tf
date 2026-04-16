# ─── GITHUB ACTIONS OIDC PROVIDER ───────────────────────────────────────────
# Allows GitHub Actions to authenticate to AWS using short-lived OIDC tokens.
# No AWS access keys are stored anywhere — tokens are issued per workflow run.

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# ─── GITHUB ACTIONS IAM ROLE ─────────────────────────────────────────────────
# Replace "repo:<your-github-username>/*" with your actual GitHub username.
# The condition ensures only workflows from YOUR repositories can assume this role.

resource "aws_iam_role" "github_actions" {
  name = "GitHubActions-CloudSec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:<your-github-username>/*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "GitHub Actions CI/CD for CloudSec project"
  }
}

# ─── SCOPED IAM POLICY ───────────────────────────────────────────────────────
# Grants only the permissions Terraform needs to manage this project.
# This replaces the previous "Action: * Resource: *" (AdministratorAccess)
# which gave GitHub Actions full control over your entire AWS account.

resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "terraform-deploy-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
          "s3:ListBucket", "s3:GetBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::cloudsec-terraform-state",
          "arn:aws:s3:::cloudsec-terraform-state/*"
        ]
      },
      {
        Sid    = "DynamoDBStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem",
          "dynamodb:DeleteItem", "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/cloudsec-terraform-locks"
      },
      {
        Sid    = "ECSManagement"
        Effect = "Allow"
        Action = ["ecs:*"]
        Resource = "*"
      },
      {
        Sid    = "EC2VPCNetworking"
        Effect = "Allow"
        Action = [
          "ec2:*Vpc*", "ec2:*Subnet*", "ec2:*RouteTable*",
          "ec2:*InternetGateway*", "ec2:*NatGateway*",
          "ec2:*SecurityGroup*", "ec2:*Address*",
          "ec2:DescribeAvailabilityZones", "ec2:DescribeAccountAttributes",
          "ec2:CreateTags", "ec2:DeleteTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "RDSManagement"
        Effect = "Allow"
        Action = ["rds:*"]
        Resource = "*"
      },
      {
        Sid    = "EFSManagement"
        Effect = "Allow"
        Action = ["elasticfilesystem:*"]
        Resource = "*"
      },
      {
        Sid    = "ALBManagement"
        Effect = "Allow"
        Action = ["elasticloadbalancing:*"]
        Resource = "*"
      },
      {
        Sid    = "IAMManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
          "iam:PassRole", "iam:AttachRolePolicy", "iam:DetachRolePolicy",
          "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
          "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
          "iam:TagRole", "iam:UntagRole",
          "iam:CreateOpenIDConnectProvider", "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider", "iam:TagOpenIDConnectProvider"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMManagement"
        Effect = "Allow"
        Action = [
          "ssm:PutParameter", "ssm:GetParameter", "ssm:GetParameters",
          "ssm:DeleteParameter", "ssm:DescribeParameters",
          "ssm:AddTagsToResource", "ssm:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchManagement"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm", "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms", "cloudwatch:TagResource",
          "logs:CreateLogGroup", "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy", "logs:DescribeLogGroups",
          "logs:ListTagsLogGroup", "logs:TagLogGroup",
          "logs:CreateLogDelivery", "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSManagement"
        Effect = "Allow"
        Action = [
          "sns:CreateTopic", "sns:DeleteTopic", "sns:GetTopicAttributes",
          "sns:SetTopicAttributes", "sns:Subscribe", "sns:Unsubscribe",
          "sns:ListTagsForResource", "sns:TagResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "Route53Management"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:GetChange"
        ]
        Resource = "*"
      },
      {
        Sid    = "AppAutoScaling"
        Effect = "Allow"
        Action = ["application-autoscaling:*"]
        Resource = "*"
      }
    ]
  })
}

output "github_actions_role_arn" {
  description = "Add this ARN as the AWS_ROLE_ARN secret in your GitHub repository"
  value       = aws_iam_role.github_actions.arn
}
