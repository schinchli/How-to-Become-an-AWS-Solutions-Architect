# How to Become an AWS Solutions Architect: A Practical Hands-On Guide

**Master AWS Architecture Through Real-World Labs**

[![AWS](https://img.shields.io/badge/AWS-Solutions%20Architecture-FF9900?logo=amazon-aws)](https://aws.amazon.com/architecture/)
[![Well-Architected](https://img.shields.io/badge/AWS-Well--Architected-blue)](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Why This Repository?

This is a hands-on learning path for developers, DevOps engineers, and cloud professionals preparing for the **AWS Solutions Architect Associate** exam or building production-ready AWS skills.

Each lab implements **real-world AWS patterns** aligned with the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html).

---

## Learning Approach

- **Deploy real AWS infrastructure** — not simulations
- **Production-grade patterns** — used in enterprise environments
- **Cost-transparent** — pricing breakdowns and cleanup scripts included
- **Well-Architected aligned** — follows AWS best practices

---

## Available Labs

| # | Lab | Domain | Services | Duration | Level |
|---|-----|--------|----------|----------|-------|
| 1 | [IAM Fundamentals](Hands%20on%20Labs/Lab-01-IAM-Fundamentals/README.md) | Identity | IAM, Policies, Roles | 20 min | Beginner |
| 2 | [S3 + CloudFront Static Website](Hands%20on%20Labs/Lab-02-S3-CloudFront-Static-Website/README.md) | Storage | S3, CloudFront, ACM | 30 min | Beginner |
| 3 | [WordPress on ECS Fargate](Hands%20on%20Labs/Lab-03-WordPress-ECS/README.md) | Compute | ECS, Fargate, ALB, VPC | 45 min | Intermediate |
| 4 | [Securing RDS Credentials (Zero-Downtime Rotation)](https://github.com/schinchli/Security-Engineering-on-AWS/tree/main/Hands%20on%20Labs/Securing%20RDS%20Database%20Credentials%20with%20AWS%20KMS%20and%20Secrets%20Manager%20(Hands-On%2C%20Zero-Downtime%20Rotation)) | Security | KMS, Secrets Manager, RDS, Lambda | 45 min | Intermediate |
| 5 | [RDS Secrets with KMS](https://github.com/schinchli/Security-Engineering-on-AWS/blob/main/Hands%20on%20Labs/Securing%20RDS%20Database%20Credentials%20with%20AWS%20KMS%20and%20Secrets%20Manager%20(Hands-On%2C%20Zero-Downtime%20Rotation)/README.md) | Security | KMS, Secrets Manager, RDS | 30 min | Intermediate |

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/schinchli/How-to-Become-an-AWS-Solutions-Architect.git

# Navigate to a lab
cd "Hands on Labs/Lab-01-IAM-Fundamentals"

# Follow the README for step-by-step instructions
```

---

## Who This Is For

| Role | What You'll Gain |
|------|------------------|
| **AWS Certification Candidates** | Hands-on prep for Solutions Architect Associate |
| **Cloud Engineers** | Production-ready deployment patterns |
| **DevOps Professionals** | Infrastructure automation and security practices |
| **Developers** | Understanding of AWS services and architecture |

---

## Prerequisites

- AWS CLI installed and configured (`aws --version`)
- AWS account with appropriate permissions
- Basic command line knowledge
- Git for cloning repositories

---

## Security Standards

All labs follow strict security practices:

- No hardcoded credentials — secrets generated dynamically
- Least-privilege IAM policies
- Encryption at rest and in transit
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) alignment
- Complete cleanup scripts to avoid unexpected charges

---

## AWS References

| Resource | Link |
|----------|------|
| AWS Architecture Center | [Documentation](https://aws.amazon.com/architecture/) |
| Well-Architected Framework | [Documentation](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) |
| AWS Security Best Practices | [Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/welcome.html) |
| AWS Solutions Library | [Solutions](https://aws.amazon.com/solutions/) |

---

## Contributing

Found an issue or want to improve a lab?

1. Fork the repository
2. Create a feature branch
3. Follow existing documentation patterns
4. Ensure no sensitive data is committed
5. Submit a pull request

---

## License

MIT License — free for learning and commercial use.

---

## Author

**Shashank Chinchli** — AWS Solutions Architect & Golden Jacket Holder

[![GitHub](https://img.shields.io/badge/GitHub-schinchli-black?logo=github)](https://github.com/schinchli)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-shashankk-blue?logo=linkedin)](https://www.linkedin.com/in/shashankk/)

---

**Build real AWS skills. Think like a Solutions Architect. Engineer like production.**

Star this repository to follow upcoming AWS labs.
