# 🚀 Three Tier AWS DevOps Project (Flask + Terraform + Jenkins)

## 📌 Overview
This project demonstrates a fully automated **3-tier cloud architecture** deployed on AWS using Infrastructure as Code (Terraform) and CI/CD (Jenkins).

It includes:
- Frontend (optional)
- Backend (Flask Python API)
- Database (AWS RDS MySQL)
- Load Balancer (ALB with HTTPS)
- CI/CD pipeline using Jenkins
- Infrastructure automation using Terraform

---

## 🏗️ Architecture

User → HTTPS ALB → EC2 (Flask App - Auto Scaling) → RDS MySQL


---

## ☁️ AWS Services Used

- Amazon EC2 (2+ instances / Auto Scaling)
- Application Load Balancer (ALB)
- Amazon RDS (MySQL)
- VPC (Custom networking)
- Security Groups
- IAM Roles
- AWS ACM (SSL - optional upgrade)

---

## ⚙️ DevOps Tools Used

- Terraform (Infrastructure as Code)
- Jenkins (CI/CD Pipeline)
- Git & GitHub (Version Control)
- Bash Scripting (Automation)

---

## 🐍 Backend (Flask API)

Features:
- REST APIs
- MySQL integration (RDS)
- Health check endpoint
- CRUD operations

Example endpoints:

GET / → Home
GET /health → Health check
GET /users → Fetch users
POST /add-user → Add user



---

## 🚀 CI/CD Pipeline

GitHub Push → Jenkins → Terraform Apply → AWS Infra Update → App Deployment


Stages:
1. Checkout Code
2. Terraform Init
3. Terraform Apply
4. Deploy Flask App

---

## 📦 Infrastructure as Code (Terraform)

Terraform provisions:
- VPC
- EC2 instances / Auto Scaling Group
- ALB (Load Balancer)
- RDS MySQL Database
- Security Groups

---

## 🔐 Security

- ALB handles HTTPS traffic
- RDS is private (no public access)
- Security groups restrict traffic between tiers

---

## 📊 Monitoring (Optional Upgrade)

- AWS CloudWatch metrics
- CPU alarms
- Logging support

---

## 🛠️ How to Run Locally

```bash
cd backend
pip install -r requirements.txt
python app.py


☁️ Deployment Flow

Developer → GitHub → Jenkins → Terraform → AWS (EC2 + ALB + RDS)