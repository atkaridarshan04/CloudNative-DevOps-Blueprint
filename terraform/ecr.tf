resource "aws_ecr_repository" "frontend" {
  name = "bookstore-frontend"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project = "Bookstore"
    Service = "Frontend"
  }
}

resource "aws_ecr_repository" "backend" {
  name = "bookstore-backend"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project = "Bookstore"
    Service = "Backend"
  }
}
